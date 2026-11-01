#pragma once

#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class Brightness : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(qreal level READ level NOTIFY levelChanged)
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(QString device READ device CONSTANT)

public:
    explicit Brightness(QObject* parent = nullptr);

    qreal level() const { return m_level; }
    bool available() const { return !m_dir.isEmpty(); }
    QString device() const { return m_device; }

signals:
    void levelChanged();

private:
    void findDevice();
    void poll();

    QString m_dir;
    QString m_device;
    int m_max = 0;
    qreal m_level = 0;
    bool m_seen = false;
    QTimer m_timer;
};