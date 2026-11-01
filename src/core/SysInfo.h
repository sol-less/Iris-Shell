#pragma once

#include <QObject>
#include <QString>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class Battery : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(int percent READ percent NOTIFY changed)
    Q_PROPERTY(bool charging READ charging NOTIFY changed)
    Q_PROPERTY(bool full READ full NOTIFY changed)

public:
    explicit Battery(QObject* parent = nullptr);
    bool available() const { return !m_dir.isEmpty(); }
    int percent() const { return m_percent; }
    bool charging() const { return m_charging; }
    bool full() const { return m_full; }

signals:
    void changed();
    void low(int percent);      // dropped to 20% or less while discharging

private:
    void poll();
    QString m_dir;
    int m_percent = 0;
    bool m_charging = false, m_full = false, m_warned = false;
    QTimer m_timer;
};

class Network : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool connected READ connected NOTIFY changed)
    Q_PROPERTY(QString type READ type NOTIFY changed)    // "wifi" | "ethernet" | "none"
    Q_PROPERTY(int signal READ signal NOTIFY changed)    // 0 to 100, wifi only

public:
    explicit Network(QObject* parent = nullptr);
    bool connected() const { return m_type != QLatin1String("none"); }
    QString type() const { return m_type; }
    int signal() const { return m_signal; }

signals:
    void changed();

private:
    void poll();
    QString m_type = QStringLiteral("none");
    int m_signal = 0;
    QTimer m_timer;
};