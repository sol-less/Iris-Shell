#include "Countdown.h"

Countdown::Countdown(QObject* parent) : QObject(parent) {
    m_timer.setInterval(250);
    connect(&m_timer, &QTimer::timeout, this, &Countdown::tick);
}

QString Countdown::text() const {
    const qint64 s = qMax<qint64>(0, (m_remaining + 999) / 1000);
    const int h = int(s / 3600), m = int((s % 3600) / 60), sec = int(s % 60);
    const QChar z = QLatin1Char('0');
    return h > 0 ? QStringLiteral("%1:%2:%3").arg(h).arg(m, 2, 10, z).arg(sec, 2, 10, z)
                 : QStringLiteral("%1:%2").arg(m, 2, 10, z).arg(sec, 2, 10, z);
}

void Countdown::start(int minutes, const QString& label) {
    if (minutes <= 0) return;
    m_total = qint64(minutes) * 60 * 1000;
    m_remaining = m_total;
    m_label = label;
    m_active = true;
    m_running = false;
    resume();
}

void Countdown::resume() {
    if (!m_active || m_running) return;
    m_running = true;
    m_clock.start();
    m_last = 0;
    m_timer.start();
    emit changed();
}

void Countdown::pause() {
    if (!m_running) return;
    tick();                                            // count up to this moment
    if (!m_running) return;                            // it just finished
    m_running = false;
    m_timer.stop();
    emit changed();
}

void Countdown::toggle() {
    if (m_running) pause();
    else resume();
}

void Countdown::cancel() {
    m_timer.stop();
    m_running = false;
    m_active = false;
    m_remaining = 0;
    emit changed();
}

void Countdown::addMinutes(int minutes) {
    if (!m_active) return;
    m_remaining += qint64(minutes) * 60 * 1000;
    m_total += qint64(minutes) * 60 * 1000;
    emit changed();
}

void Countdown::tick() {
    const qint64 now = m_clock.elapsed();
    m_remaining -= (now - m_last);
    m_last = now;

    if (m_remaining <= 0) {
        const QString label = m_label;
        cancel();
        emit finished(label);
        return;
    }
    emit changed();
}