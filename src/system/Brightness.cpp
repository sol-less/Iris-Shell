#include "Brightness.h"

#include <algorithm>
#include <QProcess>
#include <cmath>
#include <QDir>
#include <QFile>

static int readInt(const QString& path, bool* ok) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) { *ok = false; return 0; }
    return f.readAll().trimmed().toInt(ok);
}

Brightness::Brightness(QObject* parent) : QObject(parent) {
    findDevice();
    if (m_dir.isEmpty()) return;

    m_timer.setInterval(250);
    connect(&m_timer, &QTimer::timeout, this, &Brightness::poll);
    m_timer.start();
    poll();
}

void Brightness::findDevice() {
    const QDir root(QStringLiteral("/sys/class/backlight"));
    int bestMax = 0;

    m_apply.setSingleShot(true);
    m_apply.setInterval(60);                         // a dragged slider runs the command at most every 60 ms
    connect(&m_apply, &QTimer::timeout, this, [this] {
        if (m_pending < 0) return;
        QProcess::startDetached(QStringLiteral("brightnessctl"),
                                {QStringLiteral("set"), QString::number(m_pending) + QStringLiteral("%")});
        m_pending = -1;
    });

    for (const QString& dev : root.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        bool ok = false;
        const int max = readInt(root.filePath(dev + QStringLiteral("/max_brightness")), &ok);
        if (ok && max > bestMax) {
            bestMax = max;
            m_max = max;
            m_device = dev;
            m_dir = root.filePath(dev);
        }
    }
}

void Brightness::poll() {
    bool ok = false;
    const int cur = readInt(m_dir + QStringLiteral("/brightness"), &ok);
    if (!ok || m_max <= 0) return;

    const qreal level = std::clamp(qreal(cur) / m_max, 0.0, 1.0);

    if (!m_seen) {
        m_seen = true;
        m_level = level;
        return;
    }
    if (qAbs(level - m_level) < 0.0005) return;

    m_level = level;
    emit levelChanged();
}

void Brightness::setLevel(qreal level) {
    m_pending = qBound(1, int(std::round(level * 100.0)), 100);
    if (!m_apply.isActive()) m_apply.start();
}