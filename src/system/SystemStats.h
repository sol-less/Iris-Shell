#pragma once

#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class SystemStats : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)   // polls only while true
    Q_PROPERTY(qreal cpu READ cpu NOTIFY changed)             // 0 to 1
    Q_PROPERTY(qreal ram READ ram NOTIFY changed)
    Q_PROPERTY(qreal disk READ disk NOTIFY changed)           // the root filesystem
    Q_PROPERTY(qreal temp READ temp NOTIFY changed)           // degrees C, -1 if unknown
    Q_PROPERTY(QString ramText READ ramText NOTIFY changed)
    Q_PROPERTY(QString uptime READ uptime NOTIFY changed)
    Q_PROPERTY(QVariantList cpuHistory READ cpuHistory NOTIFY changed)

public:
    explicit SystemStats(QObject* parent = nullptr);

    bool enabled() const { return m_timer.isActive(); }
    void setEnabled(bool on);
    qreal cpu() const { return m_cpu; }
    qreal ram() const { return m_ram; }
    qreal disk() const { return m_disk; }
    qreal temp() const { return m_temp; }
    QString ramText() const { return m_ramText; }
    QString uptime() const { return m_uptime; }
    QVariantList cpuHistory() const { return m_history; }

signals:
    void changed();
    void enabledChanged();

private:
    void poll();

    QTimer m_timer;
    qint64 m_lastTotal = 0, m_lastIdle = 0;
    qreal m_cpu = 0, m_ram = 0, m_disk = 0, m_temp = -1;
    QString m_ramText, m_uptime;
    QVariantList m_history;
    QStringList m_tempFiles;
    bool m_scanned = false;
};