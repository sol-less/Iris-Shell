#include "Config.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSaveFile>

namespace {

QJsonObject defaults() {
    return QJsonObject{
        {"appearance", QJsonObject{{"font", "Inter"}}},
        {"notch", QJsonObject{{"loop", true}, {"swipeThreshold", 40}, {"dragRange", 120},
                              {"showNetwork", true}, {"showBattery", true},
                              {"radius", 12}, {"shadow", 0.6}, {"opacity", 1.0}}},
        {"launcher", QJsonObject{{"iconSize", 22}, {"maxWidth", 300}}},
        {"media", QJsonObject{{"squiggle", 0.6}}},
        {"osd", QJsonObject{{"volume", true}, {"brightness", true}, {"squiggle", 0.6}, {"ms", 1600}}},
        {"notifications", QJsonObject{{"dnd", false}, {"ms", 4500}, {"criticalMs", 8000}}},
        {"apps", QJsonObject{{"includeHidden", false}, {"includeTerminal", false}, {"terminal", ""},
                             {"excludeNames", QJsonArray{}}, {"excludeCategories", QJsonArray{}}}},
        {"wallpaper", QJsonObject{{"folder", "~/Pictures/Wallpapers"}, {"perPage", 7},
                                  {"tileWidth", 150}, {"dim", 0.4}, {"animMs", 450}}},
        {"cava", QJsonObject{{"bars", 20}, {"framerate", 60}, {"inputMethod", ""}, {"onlyWhenPlaying", true},
                             {"barWidth", 15}, {"barSpacing", 4}}},
    };
}

QJsonObject deepMerge(QJsonObject base, const QJsonObject& over) {
    for (auto it = over.begin(); it != over.end(); ++it) {
        if (it.value().isObject() && base.value(it.key()).isObject())
            base[it.key()] = deepMerge(base.value(it.key()).toObject(), it.value().toObject());
        else
            base[it.key()] = it.value();
    }
    return base;
}

void setPath(QJsonObject& obj, const QStringList& p, int i, const QJsonValue& v) {
    if (i == p.size() - 1) { obj[p[i]] = v; return; }
    QJsonObject child = obj.value(p[i]).toObject();
    setPath(child, p, i + 1, v);
    obj[p[i]] = child;
}

void removePath(QJsonObject& obj, const QStringList& p, int i) {
    if (i == p.size() - 1) { obj.remove(p[i]); return; }
    QJsonObject child = obj.value(p[i]).toObject();
    removePath(child, p, i + 1);
    if (child.isEmpty()) obj.remove(p[i]);
    else obj[p[i]] = child;
}

}  // namespace

Config::Config(QObject* parent) : QObject(parent) {
    m_path = qEnvironmentVariable("XDG_CONFIG_HOME", QDir::homePath() + QStringLiteral("/.config"))
             + QStringLiteral("/quickshell/config/iris.json");

    m_reload.setSingleShot(true);
    m_reload.setInterval(100);
    connect(&m_reload, &QTimer::timeout, this, [this] { rewatch(); load(); });
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, &m_reload, qOverload<>(&QTimer::start));
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, &m_reload, qOverload<>(&QTimer::start));

    m_save.setSingleShot(true);
    m_save.setInterval(250);                    // a dragged slider writes the file once, not 60 times
    connect(&m_save, &QTimer::timeout, this, &Config::save);

    rewatch();
    load();
}

void Config::rewatch() {
    if (!m_watcher.files().isEmpty()) m_watcher.removePaths(m_watcher.files());
    if (!m_watcher.directories().isEmpty()) m_watcher.removePaths(m_watcher.directories());
    const QFileInfo info(m_path);
    if (info.dir().exists()) m_watcher.addPath(info.absolutePath());
    if (info.exists()) m_watcher.addPath(info.absoluteFilePath());
}

void Config::load() {
    QFile f(m_path);
    if (!f.open(QIODevice::ReadOnly)) {
        m_user = {};
        rebuild();
        return;
    }
    const QByteArray bytes = f.readAll();
    if (bytes == m_lastWritten) return;         // our own save

    QJsonParseError pe;
    const QJsonDocument doc = QJsonDocument::fromJson(bytes, &pe);
    if (pe.error != QJsonParseError::NoError || !doc.isObject()) {
        qWarning() << "Config:" << m_path << pe.errorString() << "(keeping the previous settings)";
        return;
    }
    m_user = doc.object();
    rebuild();
}

void Config::rebuild() {
    m_merged = deepMerge(defaults(), m_user);
    const QVariantMap next = m_merged.toVariantMap();
    if (next == m_data) return;
    m_data = next;
    emit dataChanged();
}

QVariant Config::get(const QString& key) const {
    QJsonValue v = m_merged;
    for (const QString& part : key.split('.')) v = v.toObject().value(part);
    return v.toVariant();
}

void Config::set(const QString& key, const QVariant& value) {
    setPath(m_user, key.split('.'), 0, QJsonValue::fromVariant(value));
    rebuild();
    scheduleSave();
}

void Config::reset(const QString& key) {
    removePath(m_user, key.split('.'), 0);
    rebuild();
    scheduleSave();
}

void Config::resetAll() {
    m_user = {};
    rebuild();
    scheduleSave();
}

void Config::scheduleSave() { m_save.start(); }

void Config::save() {
    const QByteArray bytes = QJsonDocument(m_user).toJson(QJsonDocument::Indented);
    QDir().mkpath(QFileInfo(m_path).absolutePath());
    QSaveFile f(m_path);
    if (f.open(QIODevice::WriteOnly) && f.write(bytes) >= 0) {
        m_lastWritten = bytes;
        f.commit();
    }
}