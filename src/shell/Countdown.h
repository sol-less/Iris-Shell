#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QString>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class Countdown : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool active READ active NOTIFY changed)        // running or paused
    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(qreal progress READ progress NOTIFY changed)   // 1 -> 0
    Q_PROPERTY(QString text READ text NOTIFY changed)         // "12:34"
    Q_PROPERTY(QString label READ label NOTIFY changed)

public:
    explicit Countdown(QObject* parent = nullptr);

    bool active() const { return m_active; }
    bool running() const { return m_running; }
    qreal progress() const { return m_total > 0 ? qreal(m_remaining) / qreal(m_total) : 0.0; }
    QString text() const;
    QString label() const { return m_label; }

    Q_INVOKABLE void start(int minutes, const QString& label = QString());
    Q_INVOKABLE void pause();
    Q_INVOKABLE void resume();
    Q_INVOKABLE void toggle();
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void addMinutes(int minutes);

signals:
    void changed();
    void finished(const QString& label);

private:
    void tick();

    QTimer m_timer;
    QElapsedTimer m_clock;
    qint64 m_last = 0;
    qint64 m_remaining = 0;
    qint64 m_total = 0;
    bool m_active = false;
    bool m_running = false;
    QString m_label;
};