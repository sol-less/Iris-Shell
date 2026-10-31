#include "Cava.h"

#include <algorithm>
#include <iterator>

#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusVariant>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>
#include <QStandardPaths>

static const QString kMprisPrefix = QStringLiteral("org.mpris.MediaPlayer2.");
static const QString kMprisPath = QStringLiteral("/org/mpris/MediaPlayer2");
static const QString kPlayerIface = QStringLiteral("org.mpris.MediaPlayer2.Player");
static const QString kPropsIface = QStringLiteral("org.freedesktop.DBus.Properties");

Cava::Cava(QObject* parent) : QObject(parent) {
    m_values = QList<qreal>(m_bars, 0.0);
    m_installed = !QStandardPaths::findExecutable(QStringLiteral("cava")).isEmpty();
    if (!m_installed) m_errorString = QStringLiteral("cava was not found in PATH");

    connect(&m_proc, &QProcess::readyReadStandardOutput, this, &Cava::onOutput);
    connect(&m_proc, &QProcess::stateChanged, this, [this](QProcess::ProcessState state) {
        const bool running = state == QProcess::Running;
        if (running == m_running) return;
        m_running = running;
        emit runningChanged();
        if (!running) zeroValues();
    });
    connect(&m_proc, &QProcess::errorOccurred, this, [this](QProcess::ProcessError err) {
        if (err == QProcess::FailedToStart)
            setError(QStringLiteral("Failed to start cava"));
    });
    connect(&m_proc, &QProcess::finished, this, [this](int code, QProcess::ExitStatus) {
        if (code != 0) {
            const QString err = QString::fromUtf8(m_proc.readAllStandardError()).trimmed();
            if (!err.isEmpty()) setError(err);
        }
    });

    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.connect(QStringLiteral("org.freedesktop.DBus"), QStringLiteral("/org/freedesktop/DBus"),
                QStringLiteral("org.freedesktop.DBus"), QStringLiteral("NameOwnerChanged"),
                this, SLOT(onNameOwnerChanged(QString,QString,QString)));
    bus.connect(QString(), kMprisPath, kPropsIface, QStringLiteral("PropertiesChanged"),
                this, SLOT(onPropertiesChanged(QDBusMessage)));

    m_pruneTimer.setInterval(2000);
    connect(&m_pruneTimer, &QTimer::timeout, this, [this] {
        pruneGone();
        recompute();
    });
    m_pruneTimer.start();

    m_cfgDebounce.setSingleShot(true);
    m_cfgDebounce.setInterval(100);
    connect(&m_cfgDebounce, &QTimer::timeout, this, [this] {
        rewatchConfig();
        loadConfig();
    });
    connect(&m_cfgWatcher, &QFileSystemWatcher::fileChanged, &m_cfgDebounce,
            qOverload<>(&QTimer::start));
    connect(&m_cfgWatcher, &QFileSystemWatcher::directoryChanged, &m_cfgDebounce,
            qOverload<>(&QTimer::start));

    setConfigPath(qEnvironmentVariable("XDG_CONFIG_HOME",
                      QDir::homePath() + QStringLiteral("/.config"))
                  + QStringLiteral("/quickshell/cava.json"));

    scanPlayers();
    update();
}

Cava::~Cava() {
    m_proc.disconnect(this);
    if (m_proc.state() != QProcess::NotRunning) {
        m_proc.terminate();
        if (!m_proc.waitForFinished(300)) m_proc.kill();
    }
}

void Cava::setBars(int bars) {
    bars = std::clamp(bars, 1, 512);
    if (bars == m_bars) return;
    m_bars = bars;
    m_values.resize(bars);
    emit barsChanged();
    emit valuesChanged();
    restart();
}

void Cava::setFramerate(int fps) {
    fps = std::clamp(fps, 1, 240);
    if (fps == m_framerate) return;
    m_framerate = fps;
    emit framerateChanged();
    restart();
}

void Cava::setEnabled(bool enabled) {
    if (enabled == m_enabled) return;
    m_enabled = enabled;
    emit enabledChanged();
    update();
}

void Cava::setOnlyWhenPlaying(bool only) {
    if (only == m_onlyWhenPlaying) return;
    m_onlyWhenPlaying = only;
    emit onlyWhenPlayingChanged();
    update();
}

void Cava::setInputMethod(const QString& method) {
    if (method == m_inputMethod) return;
    m_inputMethod = method;
    emit inputMethodChanged();
    restart();
}

void Cava::setError(const QString& error) {
    if (error == m_errorString) return;
    m_errorString = error;
    emit errorStringChanged();
}

void Cava::setConfigPath(const QString& path) {
    if (path == m_configPath) return;
    m_configPath = path;
    m_configResolved = path.startsWith(QLatin1String("~/"))
                           ? QDir::homePath() + path.mid(1)
                           : path;
    emit configPathChanged();
    rewatchConfig();
    loadConfig();
}

void Cava::rewatchConfig() {
    if (!m_cfgWatcher.files().isEmpty())
        m_cfgWatcher.removePaths(m_cfgWatcher.files());
    if (!m_cfgWatcher.directories().isEmpty())
        m_cfgWatcher.removePaths(m_cfgWatcher.directories());
    if (m_configResolved.isEmpty()) return;

    const QFileInfo info(m_configResolved);
    if (info.dir().exists()) m_cfgWatcher.addPath(info.absolutePath());
    if (info.exists()) m_cfgWatcher.addPath(info.absoluteFilePath());
}

void Cava::loadConfig() {
    if (m_configResolved.isEmpty()) return;
    QFile file(m_configResolved);
    if (!file.open(QIODevice::ReadOnly)) return;

    QJsonParseError pe;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &pe);
    if (pe.error != QJsonParseError::NoError || !doc.isObject()) {
        setError(QStringLiteral("cava.json: %1").arg(pe.errorString()));
        return;
    }

    const QJsonObject o = doc.object();
    m_applying = true;
    if (o.contains("bars")) setBars(o.value("bars").toInt(m_bars));
    if (o.contains("framerate")) setFramerate(o.value("framerate").toInt(m_framerate));
    if (o.contains("inputMethod")) setInputMethod(o.value("inputMethod").toString());
    if (o.contains("onlyWhenPlaying"))
        setOnlyWhenPlaying(o.value("onlyWhenPlaying").toBool(m_onlyWhenPlaying));
    if (o.contains("enabled")) setEnabled(o.value("enabled").toBool(m_enabled));
    m_applying = false;

    if (m_dirty) { m_dirty = false; restart(); }
}

void Cava::scanPlayers() {
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) return;

    const QStringList names = bus.interface()->registeredServiceNames().value();
    for (const QString& name : names)
        if (name.startsWith(kMprisPrefix)) trackPlayer(name);
}

void Cava::trackPlayer(const QString& serviceName) {
    QDBusConnection bus = QDBusConnection::sessionBus();
    const QString owner = bus.interface()->serviceOwner(serviceName).value();
    if (owner.isEmpty()) return;
    m_names.insert(owner, serviceName.mid(kMprisPrefix.size()));

    QDBusMessage msg = QDBusMessage::createMethodCall(
        serviceName, kMprisPath, kPropsIface, QStringLiteral("Get"));
    msg << kPlayerIface << QStringLiteral("PlaybackStatus");

    auto* watcher = new QDBusPendingCallWatcher(bus.asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this, owner](QDBusPendingCallWatcher* w) {
                QDBusPendingReply<QVariant> reply = *w;
                if (reply.isValid()) {
                    QVariant v = reply.value();
                    if (v.metaType() == QMetaType::fromType<QDBusVariant>())
                        v = v.value<QDBusVariant>().variant();
                    setStatus(owner, v.toString());
                } else {
                    qWarning() << "Cava: PlaybackStatus query failed:"
                               << reply.error().message();
                    recompute();
                }
                w->deleteLater();
            });
}

void Cava::onNameOwnerChanged(const QString& name, const QString& oldOwner,
                              const QString& newOwner) {
    if (!name.startsWith(kMprisPrefix)) return;
    if (!oldOwner.isEmpty()) {
        m_status.remove(oldOwner);
        m_names.remove(oldOwner);
    }
    if (!newOwner.isEmpty()) trackPlayer(name);
    pruneGone();
    recompute();
}

void Cava::onPropertiesChanged(const QDBusMessage& msg) {
    const QList<QVariant> args = msg.arguments();
    if (args.size() < 2 || args.at(0).toString() != kPlayerIface) return;

    const QVariantMap changed = qdbus_cast<QVariantMap>(args.at(1));
    if (!changed.contains(QStringLiteral("PlaybackStatus"))) return;
    setStatus(msg.service(), changed.value(QStringLiteral("PlaybackStatus")).toString());
}

void Cava::setStatus(const QString& owner, const QString& status) {
    m_status.insert(owner, status);
    recompute();
}

void Cava::refreshNames() {
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) return;

    const QStringList names = bus.interface()->registeredServiceNames().value();
    for (const QString& name : names) {
        if (!name.startsWith(kMprisPrefix)) continue;
        const QString owner = bus.interface()->serviceOwner(name).value();
        if (!owner.isEmpty()) m_names.insert(owner, name.mid(kMprisPrefix.size()));
    }
}

void Cava::pruneGone() {
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) return;

    QSet<QString> alive;
    const QStringList names = bus.interface()->registeredServiceNames().value();
    for (const QString& name : names) {
        if (!name.startsWith(kMprisPrefix)) continue;
        const QString owner = bus.interface()->serviceOwner(name).value();
        if (!owner.isEmpty()) alive.insert(owner);
    }

    for (auto it = m_names.begin(); it != m_names.end();)
        it = alive.contains(it.key()) ? std::next(it) : m_names.erase(it);
    for (auto it = m_status.begin(); it != m_status.end();)
        it = alive.contains(it.key()) ? std::next(it) : m_status.erase(it);
}

void Cava::recompute() {
    QStringList list;
    for (const QString& n : std::as_const(m_names))
        if (n != QLatin1String("playerctld") && !list.contains(n)) list << n;
    list.sort();

    bool playing = false;
    QString who;
    for (auto it = m_status.cbegin(); it != m_status.cend(); ++it) {
        if (it.value() != QLatin1String("Playing")) continue;

        QString n = m_names.value(it.key());
        if (n.isEmpty()) {
            refreshNames();
            n = m_names.value(it.key());
        }
        if (n == QLatin1String("playerctld")) continue;

        playing = true;
        who = n;
        break;
    }
    if (who.isEmpty() && !list.isEmpty()) who = list.first();

    if (list != m_playerList) { m_playerList = list; emit playersChanged(); }

    const bool detected = !list.isEmpty();
    if (detected != m_detected) { m_detected = detected; emit availableChanged(); }
    if (playing != m_playing) { m_playing = playing; emit playingChanged(); }
    if (who != m_player) { m_player = who; emit playerChanged(); }

    update();
}

void Cava::update() {
    const bool should = m_enabled && m_installed && (!m_onlyWhenPlaying || m_playing);
    const bool running = m_proc.state() != QProcess::NotRunning;
    if (should && !running) start();
    else if (!should && running) stop();
}

void Cava::restart() {
    if (m_applying) { m_dirty = true; return; }
    if (m_proc.state() != QProcess::NotRunning) stop();
    update();
}

void Cava::start() {
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    const QString path = (dir.isEmpty() ? QDir::tempPath() : dir)
                         + QStringLiteral("/iris-cava.conf");

    QString cfg;
    cfg += QStringLiteral("[general]\nbars = %1\nframerate = %2\n\n").arg(m_bars).arg(m_framerate);
    cfg += QStringLiteral("[input]\n");
    if (!m_inputMethod.isEmpty())
        cfg += QStringLiteral("method = %1\n").arg(m_inputMethod);
    cfg += QStringLiteral("\n[output]\n"
                          "method = raw\n"
                          "raw_target = /dev/stdout\n"
                          "data_format = ascii\n"
                          "ascii_max_range = 1000\n"
                          "bar_delimiter = 59\n"
                          "frame_delimiter = 10\n"
                          "channels = mono\n");

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        setError(QStringLiteral("Cannot write %1").arg(path));
        return;
    }
    file.write(cfg.toUtf8());
    file.close();

    m_buf.clear();
    setError({});
    m_proc.start(QStringLiteral("cava"), {QStringLiteral("-p"), path});
}

void Cava::stop() {
    m_proc.terminate();
    if (!m_proc.waitForFinished(300)) {
        m_proc.kill();
        m_proc.waitForFinished(300);
    }
}

void Cava::zeroValues() {
    m_values = QList<qreal>(m_bars, 0.0);
    emit valuesChanged();
}

void Cava::onOutput() {
    m_buf += m_proc.readAllStandardOutput();

    const qsizetype end = m_buf.lastIndexOf('\n');
    if (end < 0) return;

    const QByteArray complete = m_buf.left(end);
    m_buf.remove(0, end + 1);
    const QByteArray line = complete.mid(complete.lastIndexOf('\n') + 1);
    if (line.isEmpty()) return;

    QList<qreal> values(m_bars, 0.0);
    int i = 0;
    for (const QByteArray& part : line.split(';')) {
        if (i >= m_bars) break;
        bool ok = false;
        const int v = part.trimmed().toInt(&ok);
        if (!ok) continue;
        values[i++] = std::clamp(v / 1000.0, 0.0, 1.0);
    }

    m_values = values;
    emit valuesChanged();
}