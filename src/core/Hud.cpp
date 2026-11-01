#include "Hud.h"

Hud::Hud(QObject* parent) : QObject(parent) {
    m_hide.setSingleShot(true);
    connect(&m_hide, &QTimer::timeout, this, [this] { close(false); });

    // volume and brightness report their current values right after startup, so don't show those
    QTimer::singleShot(2500, this, [this] { m_armed = true; });
}

void Hud::open(const QString& kind, int ms) {
    if (kind != m_kind) { m_kind = kind; emit kindChanged(); }
    if (!m_active) { m_active = true; emit activeChanged(); }
    m_hide.start(ms);
}

void Hud::close(bool byUser) {
    m_hide.stop();
    const bool wasNotification = m_active && m_kind == QLatin1String("notification");
    if (m_active) { m_active = false; emit activeChanged(); }
    if (wasNotification) emit notificationEnded(byUser);
}

void Hud::interruptNotification() {
    if (m_active && m_kind == QLatin1String("notification"))
        emit notificationEnded(false);
}

void Hud::showOsd(const QString& kind, qreal level, bool muted) {
    if (!m_armed) return;
    interruptNotification();   // an OSD takes over from a notification

    m_osdKind = kind;
    m_osdLevel = qMax<qreal>(0.0, level);
    m_osdMuted = muted;
    emit osdChanged();

    open(QStringLiteral("osd"), m_osdMs);
}

void Hud::showNotification(const QString& app, const QString& summary, const QString& body,
                           const QString& icon, const QString& image, bool critical) {
    interruptNotification();   // a new notification replaces the previous one

    m_app = app;
    m_summary = summary;
    m_body = body;
    m_icon = icon;
    m_image = image;
    emit notificationChanged();

    open(QStringLiteral("notification"), critical ? m_criticalMs : m_notificationMs);
}

void Hud::hide() {
    close(true);
}