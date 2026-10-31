#include "Theme.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>

static Theme* s_instance = nullptr;

Theme* Theme::instance() {
    if (!s_instance)
        s_instance = new Theme(QCoreApplication::instance(), SharedTag{});
    return s_instance;
}

Theme::Theme(QObject* parent) : QObject(parent) {
    Theme* shared = instance();
    connect(shared, &Theme::pathChanged, this, &Theme::pathChanged);
    connect(shared, &Theme::sectionChanged, this, &Theme::sectionChanged);
    connect(shared, &Theme::loadedChanged, this, &Theme::loadedChanged);
    connect(shared, &Theme::errorStringChanged, this, &Theme::errorStringChanged);
    connect(shared, &Theme::colorsChanged, this, &Theme::colorsChanged);
}

Theme::Theme(QObject* parent, SharedTag) : QObject(parent), m_shared(true) {
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(50);

    connect(&m_debounce, &QTimer::timeout, this, [this] {
        rewatch();
        reload();
    });
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, &m_debounce,
            qOverload<>(&QTimer::start));
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, &m_debounce,
            qOverload<>(&QTimer::start));

    const QString state = qEnvironmentVariable(
        "XDG_STATE_HOME", QDir::homePath() + QStringLiteral("/.local/state"));
    setPath(state + QStringLiteral("/quickshell/generated/colors.json"));
}

QString Theme::resolvePath(const QString& path) {
    if (path.startsWith(QLatin1String("file://")))
        return QUrl(path).toLocalFile();
    if (path == QLatin1String("~"))
        return QDir::homePath();
    if (path.startsWith(QLatin1String("~/")))
        return QDir::homePath() + path.mid(1);
    return path;
}

void Theme::setPath(const QString& path) {
    if (!m_shared) { instance()->setPath(path); return; }
    if (path == m_path) return;
    m_path = path;
    m_resolved = resolvePath(path);
    emit pathChanged();
    rewatch();
    reload();
}

void Theme::setSection(const QString& section) {
    if (!m_shared) { instance()->setSection(section); return; }
    if (section == m_section) return;
    m_section = section;
    emit sectionChanged();
    reload();
}

void Theme::rewatch() {
    if (!m_watcher.files().isEmpty())
        m_watcher.removePaths(m_watcher.files());
    if (!m_watcher.directories().isEmpty())
        m_watcher.removePaths(m_watcher.directories());
    if (m_resolved.isEmpty()) return;

    const QFileInfo info(m_resolved);
    if (info.dir().exists())
        m_watcher.addPath(info.absolutePath());
    if (info.exists())
        m_watcher.addPath(info.absoluteFilePath());
}

void Theme::setStatus(bool loaded, const QString& error) {
    if (m_loaded != loaded) { m_loaded = loaded; emit loadedChanged(); }
    if (m_errorString != error) { m_errorString = error; emit errorStringChanged(); }
}

void Theme::reload() {
    if (m_resolved.isEmpty()) return;

    QFile file(m_resolved);
    if (!file.open(QIODevice::ReadOnly)) {
        setStatus(false, QStringLiteral("Cannot open %1").arg(m_resolved));
        return;
    }

    QJsonParseError parseError;
    const auto doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        setStatus(false, QStringLiteral("JSON error: %1").arg(parseError.errorString()));
        return;
    }

    const QJsonObject colors = doc.object().value(m_section).toObject();
    if (colors.isEmpty()) {
        setStatus(false, QStringLiteral("Missing section \"%1\"").arg(m_section));
        return;
    }

    bool changed = false;
#define X(name, key) { \
        const QColor c(colors.value(QLatin1String(key)).toString()); \
        if (c.isValid() && c != m_##name) { m_##name = c; changed = true; } \
    }
    MD3_COLORS(X)
#undef X

    if (changed) emit colorsChanged();
    setStatus(true, {});
}