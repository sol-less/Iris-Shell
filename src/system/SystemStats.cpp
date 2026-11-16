#include "SystemStats.h"

#include <QDir>
#include <QFile>
#include <QStorageInfo>

namespace {
QByteArray readAll(const QString& path) {
    QFile f(path);
    return f.open(QIODevice::ReadOnly) ? f.readAll() : QByteArray();
}
}

SystemStats::SystemStats(QObject* parent) : QObject(parent) {
    m_timer.setInterval(1500);
    connect(&m_timer, &QTimer::timeout, this, &SystemStats::poll);
}

void SystemStats::setEnabled(bool on) {
    if (on == m_timer.isActive()) return;
    if (on) { m_lastTotal = 0; poll(); m_timer.start(); }
    else m_timer.stop();
    emit enabledChanged();
}

void SystemStats::poll() {
    const QList<QByteArray> p = readAll(QStringLiteral("/proc/stat")).split('\n').value(0).simplified().split(' ');
    if (p.size() >= 8) {
        qint64 total = 0;
        for (int i = 1; i < p.size() && i <= 8; ++i) total += p[i].toLongLong();
        const qint64 idle = p[4].toLongLong() + p[5].toLongLong();
        if (m_lastTotal > 0 && total > m_lastTotal)
            m_cpu = qBound<qreal>(0.0, 1.0 - qreal(idle - m_lastIdle) / qreal(total - m_lastTotal), 1.0);
        m_lastTotal = total;
        m_lastIdle = idle;
    }
    m_history.append(m_cpu);
    while (m_history.size() > 48) m_history.removeFirst();

    qint64 memTotal = 0, memAvail = 0;
    for (const QByteArray& line : readAll(QStringLiteral("/proc/meminfo")).split('\n')) {
        if (line.startsWith("MemTotal:")) memTotal = line.simplified().split(' ').value(1).toLongLong();
        else if (line.startsWith("MemAvailable:")) memAvail = line.simplified().split(' ').value(1).toLongLong();
    }
    if (memTotal > 0) {
        m_ram = 1.0 - qreal(memAvail) / qreal(memTotal);
        m_ramText = QStringLiteral("%1 / %2 GB").arg((memTotal - memAvail) / 1048576.0, 0, 'f', 1)
                                                  .arg(memTotal / 1048576.0, 0, 'f', 1);
    }

    const QStorageInfo root = QStorageInfo::root();
    if (root.bytesTotal() > 0) m_disk = 1.0 - qreal(root.bytesAvailable()) / qreal(root.bytesTotal());

    if (!m_scanned) {
        m_scanned = true;
        for (const QString& z : QDir(QStringLiteral("/sys/class/thermal")).entryList({QStringLiteral("thermal_zone*")}, QDir::Dirs))
            m_tempFiles << QStringLiteral("/sys/class/thermal/") + z + QStringLiteral("/temp");
        if (m_tempFiles.isEmpty())
            for (const QString& h : QDir(QStringLiteral("/sys/class/hwmon")).entryList({QStringLiteral("hwmon*")}, QDir::Dirs))
                m_tempFiles << QStringLiteral("/sys/class/hwmon/") + h + QStringLiteral("/temp1_input");
    }
    qreal hottest = -1;
    for (const QString& f : std::as_const(m_tempFiles)) {
        const qreal c = readAll(f).trimmed().toDouble() / 1000.0;
        if (c > hottest && c < 130) hottest = c;
    }
    m_temp = hottest;

    const qint64 s = qint64(readAll(QStringLiteral("/proc/uptime")).split(' ').value(0).toDouble());
    const qint64 d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60;
    m_uptime = d > 0 ? QStringLiteral("%1d %2h").arg(d).arg(h) : (h > 0 ? QStringLiteral("%1h %2m").arg(h).arg(m)
                                                                         : QStringLiteral("%1m").arg(m));
    emit changed();
}