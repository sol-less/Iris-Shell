#include "Config.h"

#include <algorithm>

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSaveFile>

namespace {

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

void mergeSection(QList<QJsonObject>& list, const QJsonObject& s) {
    const QString id = s.value("id").toString();
    if (id.isEmpty()) return;

    for (QJsonObject& cur : list) {
        if (cur.value("id").toString() != id) continue;

        for (const QString& k : QStringList{"name", "sub", "badge", "special", "order"})
            if (s.contains(k)) cur[k] = s.value(k);

        QJsonArray groups = cur.value("groups").toArray();
        for (const QJsonValue& gv : s.value("groups").toArray()) {
            const QJsonObject g = gv.toObject();
            bool found = false;
            for (int i = 0; i < groups.size(); ++i) {
                QJsonObject existing = groups.at(i).toObject();
                if (existing.value("title") != g.value("title")) continue;
                QJsonArray items = existing.value("items").toArray();
                for (const QJsonValue& iv : g.value("items").toArray()) items.append(iv);
                existing["items"] = items;
                groups.replace(i, existing);
                found = true;
                break;
            }
            if (!found) groups.append(g);
        }
        cur["groups"] = groups;
        return;
    }
    list.append(s);
}

}  // namespace

Config::Config(QObject* parent) : QObject(parent) {
    const QString base = qEnvironmentVariable("XDG_CONFIG_HOME", QDir::homePath() + QStringLiteral("/.config"))
                         + QStringLiteral("/quickshell/config");
    m_path = base + QStringLiteral("/iris.json");
    const QString systemRegistry = QStringLiteral("/usr/share/iris-shell/registry");
    if (QDir(systemRegistry).exists()) {
        m_registryDir = systemRegistry;
    } else {
        m_registryDir = base + QStringLiteral("/registry");
        qWarning() << "Config: using the development registry" << m_registryDir;
    }

    m_reload.setSingleShot(true);
    m_reload.setInterval(100);
    connect(&m_reload, &QTimer::timeout, this, [this] { rewatch(); load(); });
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, &m_reload, qOverload<>(&QTimer::start));
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, &m_reload, qOverload<>(&QTimer::start));

    m_regReload.setSingleShot(true);
    m_regReload.setInterval(150);
    connect(&m_regReload, &QTimer::timeout, this, [this] { rewatchRegistry(); loadRegistry(); });
    connect(&m_regWatcher, &QFileSystemWatcher::fileChanged, &m_regReload, qOverload<>(&QTimer::start));
    connect(&m_regWatcher, &QFileSystemWatcher::directoryChanged, &m_regReload, qOverload<>(&QTimer::start));

    m_save.setSingleShot(true);
    m_save.setInterval(250);                    // a dragged slider writes the file once, not 60 times
    connect(&m_save, &QTimer::timeout, this, &Config::save);

    rewatch();
    rewatchRegistry();
    loadRegistry();                             // the defaults first
    load();                                     // then your file on top
}


void Config::rewatchRegistry() {
    if (!m_regWatcher.files().isEmpty()) m_regWatcher.removePaths(m_regWatcher.files());
    if (!m_regWatcher.directories().isEmpty()) m_regWatcher.removePaths(m_regWatcher.directories());

    if (QDir(m_registryDir).exists()) {
        m_regWatcher.addPath(m_registryDir);
        for (const QString& f : QDir(m_registryDir).entryList({QStringLiteral("*.json")}, QDir::Files))
            m_regWatcher.addPath(m_registryDir + QLatin1Char('/') + f);
    }
}

void Config::loadRegistry() {
    QList<QJsonObject> sections;

    const QStringList files = QDir(m_registryDir).entryList({QStringLiteral("*.json")}, QDir::Files, QDir::Name);
    for (const QString& name : files) {
        QFile f(m_registryDir + QLatin1Char('/') + name);
        if (!f.open(QIODevice::ReadOnly)) continue;

        QJsonParseError pe;
        const QJsonDocument doc = QJsonDocument::fromJson(f.readAll(), &pe);
        if (pe.error != QJsonParseError::NoError) {
            qWarning() << "Config registry:" << name << pe.errorString();
            continue;                           // a broken file never breaks the others
        }
        if (doc.isArray()) {
            for (const QJsonValue& v : doc.array()) mergeSection(sections, v.toObject());
        } else {
            mergeSection(sections, doc.object());
        }
    }

    std::stable_sort(sections.begin(), sections.end(), [](const QJsonObject& a, const QJsonObject& b) {
        return a.value("order").toInt(500) < b.value("order").toInt(500);
    });

    QJsonObject defaults;
    QJsonArray bindings, all;
    for (const QJsonObject& s : std::as_const(sections)) {
        all.append(s);
        for (const QJsonValue& gv : s.value("groups").toArray()) {
            for (const QJsonValue& iv : gv.toObject().value("items").toArray()) {
                const QJsonObject it = iv.toObject();
                const QString key = it.value("key").toString();
                if (key.isEmpty()) continue;

                if (it.contains("default")) setPath(defaults, key.split('.'), 0, it.value("default"));

                const QStringList bind = it.value("bind").toString().split('.');
                if (bind.size() == 2 && !bind[0].isEmpty() && !bind[1].isEmpty())
                    bindings.append(QJsonObject{{"key", key}, {"object", bind[0]}, {"property", bind[1]},
                                                {"skipEmpty", it.value("skipEmpty").toBool(false)}});
            }
        }
    }

    m_defaults = defaults;
    m_sections = all.toVariantList();
    m_bindings = bindings.toVariantList();
    rebuild();
    emit registryChanged();
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
    m_merged = deepMerge(m_defaults, m_user);
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
    if (get(key) == value) return;                // nothing changes, nothing to save
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
    if (QFile::exists(m_path)) {                // a safety copy first
        QFile::remove(m_path + QStringLiteral(".bak"));
        QFile::copy(m_path, m_path + QStringLiteral(".bak"));
    }
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