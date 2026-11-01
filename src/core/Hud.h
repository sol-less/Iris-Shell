#pragma once

#include <QObject>
#include <QString>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class Hud : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString kind READ kind NOTIFY kindChanged)     // "osd" | "notification"
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)

    // OSD data
    Q_PROPERTY(QString osdKind READ osdKind NOTIFY osdChanged)   // "volume" | "brightness"
    Q_PROPERTY(qreal osdLevel READ osdLevel NOTIFY osdChanged)
    Q_PROPERTY(bool osdMuted READ osdMuted NOTIFY osdChanged)

    // notification data
    Q_PROPERTY(QString app READ app NOTIFY notificationChanged)
    Q_PROPERTY(QString summary READ summary NOTIFY notificationChanged)
    Q_PROPERTY(QString body READ body NOTIFY notificationChanged)
    Q_PROPERTY(QString icon READ icon NOTIFY notificationChanged)
    Q_PROPERTY(QString image READ image NOTIFY notificationChanged)

    // how long things stay (ms), writable from QML
    Q_PROPERTY(int osdMs MEMBER m_osdMs)
    Q_PROPERTY(int notificationMs MEMBER m_notificationMs)
    Q_PROPERTY(int criticalMs MEMBER m_criticalMs)
    Q_PROPERTY(qreal squiggle READ squiggle WRITE setSquiggle NOTIFY squiggleChanged)   // 0 = flat, 1 = very wavy

public:
    explicit Hud(QObject* parent = nullptr);

    QString kind() const { return m_kind; }
    bool active() const { return m_active; }

    QString osdKind() const { return m_osdKind; }
    qreal osdLevel() const { return m_osdLevel; }
    bool osdMuted() const { return m_osdMuted; }

    QString app() const { return m_app; }
    QString summary() const { return m_summary; }
    QString body() const { return m_body; }
    QString icon() const { return m_icon; }
    QString image() const { return m_image; }

    Q_INVOKABLE void showOsd(const QString& kind, qreal level, bool muted);
    Q_INVOKABLE void showNotification(const QString& app, const QString& summary,
                                      const QString& body, const QString& icon,
                                      const QString& image, bool critical);
    Q_INVOKABLE void hide();   // the user dismissed it (for example by clicking)
    qreal squiggle() const { return m_squiggle; }
    void setSquiggle(qreal s) {
        s = qBound<qreal>(0.0, s, 1.0);
        if (s == m_squiggle) return;
        m_squiggle = s;
        emit squiggleChanged();
    }

signals:
    void kindChanged();
    void activeChanged();
    void osdChanged();
    void notificationChanged();
    // the notification that was showing is over: timed out, replaced or interrupted (byUser = false), or clicked away (true)
    void notificationEnded(bool byUser);
    void squiggleChanged();

private:
    void open(const QString& kind, int ms);
    void close(bool byUser);
    void interruptNotification();

    QString m_kind = QStringLiteral("osd");
    bool m_active = false;
    bool m_armed = false;    // ignores OSD events for the first moments after startup

    QString m_osdKind = QStringLiteral("volume");
    qreal m_osdLevel = 0;
    bool m_osdMuted = false;

    QString m_app, m_summary, m_body, m_icon, m_image;

    int m_osdMs = 1600;
    int m_notificationMs = 4500;
    int m_criticalMs = 8000;

    QTimer m_hide;
    qreal m_squiggle = 0.6;
};