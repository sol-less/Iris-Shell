#pragma once

#include <QDBusMessage>
#include <QFileSystemWatcher>
#include <QHash>
#include <QList>
#include <QObject>
#include <QProcess>
#include <QStringList>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class Cava : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int bars READ bars WRITE setBars NOTIFY barsChanged)
    Q_PROPERTY(int framerate READ framerate WRITE setFramerate NOTIFY framerateChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool onlyWhenPlaying READ onlyWhenPlaying WRITE setOnlyWhenPlaying NOTIFY onlyWhenPlayingChanged)
    Q_PROPERTY(QString inputMethod READ inputMethod WRITE setInputMethod NOTIFY inputMethodChanged)
    Q_PROPERTY(QString configPath READ configPath WRITE setConfigPath NOTIFY configPathChanged)

    Q_PROPERTY(QList<qreal> values READ values NOTIFY valuesChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(QString player READ player NOTIFY playerChanged)
    Q_PROPERTY(QStringList players READ players NOTIFY playersChanged)
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(bool installed READ installed CONSTANT)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorStringChanged)

public:
    explicit Cava(QObject* parent = nullptr);
    ~Cava() override;

    int bars() const { return m_bars; }
    void setBars(int bars);

    int framerate() const { return m_framerate; }
    void setFramerate(int fps);

    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    bool onlyWhenPlaying() const { return m_onlyWhenPlaying; }
    void setOnlyWhenPlaying(bool only);

    QString inputMethod() const { return m_inputMethod; }
    void setInputMethod(const QString& method);

    QString configPath() const { return m_configPath; }
    void setConfigPath(const QString& path);

    QList<qreal> values() const { return m_values; }
    bool playing() const { return m_playing; }
    QString player() const { return m_player; }
    QStringList players() const { return m_playerList; }
    bool available() const { return m_detected; }
    bool installed() const { return m_installed; }
    bool running() const { return m_running; }
    QString errorString() const { return m_errorString; }

signals:
    void barsChanged();
    void framerateChanged();
    void enabledChanged();
    void onlyWhenPlayingChanged();
    void inputMethodChanged();
    void configPathChanged();
    void valuesChanged();
    void playingChanged();
    void playerChanged();
    void playersChanged();
    void availableChanged();
    void runningChanged();
    void errorStringChanged();

private slots:
    void onOutput();
    void onNameOwnerChanged(const QString& name, const QString& oldOwner, const QString& newOwner);
    void onPropertiesChanged(const QDBusMessage& msg);

private:
    void scanPlayers();
    void trackPlayer(const QString& serviceName);
    void setStatus(const QString& owner, const QString& status);
    void refreshNames();
    void pruneGone();
    void recompute();

    void update();
    void restart();
    void start();
    void stop();
    void zeroValues();
    void setError(const QString& error);

    void loadConfig();
    void rewatchConfig();

    int m_bars = 20;
    int m_framerate = 60;
    bool m_enabled = true;
    bool m_onlyWhenPlaying = true;
    QString m_inputMethod;
    QString m_configPath;
    QString m_configResolved;

    QList<qreal> m_values;
    bool m_playing = false;
    QString m_player;
    QStringList m_playerList;
    bool m_detected = false;
    bool m_installed = false;
    bool m_running = false;
    QString m_errorString;

    QHash<QString, QString> m_status;
    QHash<QString, QString> m_names;

    bool m_applying = false;
    bool m_dirty = false;

    QProcess m_proc;
    QByteArray m_buf;
    QFileSystemWatcher m_cfgWatcher;
    QTimer m_cfgDebounce;
    QTimer m_pruneTimer;
};