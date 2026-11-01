#include "SysInfo.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>

static QString readText(const QString& path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) return {};
    return QString::fromUtf8(f.readAll()).trimmed();
}

Battery::Battery(QObject* parent) : QObject(parent) {
    const QDir root(QStringLiteral("/sys/class/power_supply"));
    for (const QString& d : root.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        if (readText(root.filePath(d + "/type")) != QLatin1String("Battery")) continue;
        if (m_dir.isEmpty() || d.startsWith(QLatin1String("BAT"))) m_dir = root.filePath(d);
    }
    if (m_dir.isEmpty()) return;     // desktop PC

    m_timer.setInterval(5000);
    connect(&m_timer, &QTimer::timeout, this, &Battery::poll);
    m_timer.start();
    poll();
}

void Battery::poll() {
    const int pct = qBound(0, readText(m_dir + "/capacity").toInt(), 100);
    const QString st = readText(m_dir + "/status");
    const bool chg = st == QLatin1String("Charging");
    const bool full = st == QLatin1String("Full");
    const bool dis = st == QLatin1String("Discharging");

    if (pct != m_percent || chg != m_charging || full != m_full) {
        m_percent = pct;
        m_charging = chg;
        m_full = full;
        emit changed();
    }

    if (dis && pct <= 20) {
        if (!m_warned) { m_warned = true; emit low(pct); }
    } else if (!dis || pct > 25) {
        m_warned = false;
    }
}

Network::Network(QObject* parent) : QObject(parent) {
    m_timer.setInterval(3000);
    connect(&m_timer, &QTimer::timeout, this, &Network::poll);
    m_timer.start();
    poll();
}

void Network::poll() {
    QString dev;
    QString type = QStringLiteral("none");

    const QDir root(QStringLiteral("/sys/class/net"));
    for (const QString& d : root.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        if (d == QLatin1String("lo")) continue;
        if (!QFileInfo::exists(root.filePath(d + "/device"))) continue;      // skip virtual interfaces
        if (readText(root.filePath(d + "/operstate")) != QLatin1String("up")) continue;
        dev = d;
        type = QFileInfo::exists(root.filePath(d + "/wireless")) ? QStringLiteral("wifi")
                                                                 : QStringLiteral("ethernet");
        if (type == QLatin1String("ethernet")) break;                        // prefer wired
    }

    int sig = 0;
    if (type == QLatin1String("wifi")) {
        sig = 60;
        QFile f(QStringLiteral("/proc/net/wireless"));
        if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
            while (!f.atEnd()) {
                const QString line = QString::fromUtf8(f.readLine()).trimmed();
                if (!line.startsWith(dev + ':')) continue;
                const QStringList p = line.split(QRegularExpression("\\s+"));
                if (p.size() > 2) sig = qBound(0, int(p.at(2).toDouble() / 70.0 * 100.0), 100);
            }
        }
    }

    if (type != m_type || sig != m_signal) {
        m_type = type;
        m_signal = sig;
        emit changed();
    }
}