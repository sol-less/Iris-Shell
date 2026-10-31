#include "Applications.h"

#include <algorithm>

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QHash>
#include <QLocale>
#include <QProcess>
#include <QSet>

static bool shownInCurrentDesktop(const QHash<QString, QString>& kv) {
    const QStringList current =
        qEnvironmentVariable("XDG_CURRENT_DESKTOP").split(':', Qt::SkipEmptyParts);

    const QStringList only = kv.value("OnlyShowIn").split(';', Qt::SkipEmptyParts);
    if (!only.isEmpty()) {
        bool match = false;
        for (const QString& d : current) match = match || only.contains(d);
        if (!match) return false;
    }

    const QStringList not_ = kv.value("NotShowIn").split(';', Qt::SkipEmptyParts);
    for (const QString& d : current)
        if (not_.contains(d)) return false;

    return true;
}

static bool parseDesktopFile(const QString& path, const QString& appId, AppEntry& out) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return false;

    QHash<QString, QString> kv;
    bool inEntry = false;
    while (!file.atEnd()) {
        const QString line = QString::fromUtf8(file.readLine()).trimmed();
        if (line.isEmpty() || line.startsWith('#')) continue;
        if (line.startsWith('[')) {
            if (inEntry) break;
            inEntry = (line == QLatin1String("[Desktop Entry]"));
            continue;
        }
        if (!inEntry) continue;
        const int eq = line.indexOf('=');
        if (eq <= 0) continue;
        kv.insert(line.left(eq).trimmed(), line.mid(eq + 1).trimmed());
    }

    if (kv.value("Type") != QLatin1String("Application")) return false;
    if (kv.value("Hidden") == QLatin1String("true")) return false;
    if (kv.value("Exec").isEmpty()) return false;

    const QString full = QLocale().name();
    const QString lang = full.section('_', 0, 0);
    auto loc = [&](const QString& key) -> QString {
        for (const QString& k : {key + '[' + full + ']', key + '[' + lang + ']'})
            if (kv.contains(k)) return kv.value(k);
        return kv.value(key);
    };

    out.appId = appId;
    out.name = loc("Name");
    if (out.name.isEmpty()) return false;
    out.genericName = loc("GenericName");
    out.comment = loc("Comment");
    out.icon = kv.value("Icon");
    out.exec = kv.value("Exec");
    out.keywords = loc("Keywords").replace(';', ' ');
    out.categories = kv.value("Categories").split(';', Qt::SkipEmptyParts);
    out.terminal = kv.value("Terminal") == QLatin1String("true");
    out.noDisplay = kv.value("NoDisplay") == QLatin1String("true")
                    || !shownInCurrentDesktop(kv);
    return true;
}

Applications::Applications(QObject* parent)
    : QAbstractListModel(parent),
      m_terminal(qEnvironmentVariable("TERMINAL", QStringLiteral("xterm"))) {
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(300);
    connect(&m_debounce, &QTimer::timeout, this, &Applications::reload);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, &m_debounce,
            qOverload<>(&QTimer::start));

    reload();
}

QStringList Applications::searchDirs() {
    const QString home = qEnvironmentVariable(
        "XDG_DATA_HOME", QDir::homePath() + QStringLiteral("/.local/share"));

    QStringList dirs;
    dirs << home + QStringLiteral("/applications");

    const QString xdg = qEnvironmentVariable(
        "XDG_DATA_DIRS", QStringLiteral("/usr/local/share:/usr/share"));
    for (const QString& d : xdg.split(':', Qt::SkipEmptyParts))
        dirs << d + QStringLiteral("/applications");

    dirs << home + QStringLiteral("/flatpak/exports/share/applications");
    dirs << QStringLiteral("/var/lib/flatpak/exports/share/applications");

    dirs.removeDuplicates();
    return dirs;
}

void Applications::reload() {
    rescan();
    rewatch();
}

void Applications::rewatch() {
    if (!m_watcher.directories().isEmpty())
        m_watcher.removePaths(m_watcher.directories());
    for (const QString& dir : searchDirs())
        if (QDir(dir).exists()) m_watcher.addPath(dir);
}

void Applications::rescan() {
    QList<AppEntry> entries;
    QSet<QString> seen;

    for (const QString& dir : searchDirs()) {
        const QDir d(dir);
        if (!d.exists()) continue;

        QDirIterator it(dir, {QStringLiteral("*.desktop")}, QDir::Files,
                        QDirIterator::Subdirectories | QDirIterator::FollowSymlinks);
        while (it.hasNext()) {
            const QString path = it.next();
            QString appId = d.relativeFilePath(path);
            appId.chop(8);
            appId.replace('/', '-');

            if (seen.contains(appId)) continue;
            seen.insert(appId);

            AppEntry entry;
            if (parseDesktopFile(path, appId, entry)) entries.append(entry);
        }
    }

    std::sort(entries.begin(), entries.end(), [](const AppEntry& a, const AppEntry& b) {
        return a.name.compare(b.name, Qt::CaseInsensitive) < 0;
    });

    beginResetModel();
    m_all = entries;
    filter();
    endResetModel();
    emit countChanged();
}

void Applications::filter() {
    m_visible.clear();
    const QString q = m_query.trimmed().toLower();

    auto allowed = [this](const AppEntry& e) {
        const bool isTerminal = e.terminal
                                || e.categories.contains(QStringLiteral("TerminalEmulator"));
        if (!m_includeHidden && e.noDisplay) return false;
        if (!m_includeTerminal && isTerminal) return false;
        for (const QString& c : m_excludeCategories)
            if (e.categories.contains(c)) return false;
        for (const QString& n : m_excludeNames)
            if (e.name.contains(n, Qt::CaseInsensitive)) return false;
        return true;
    };

    if (q.isEmpty()) {
        for (int i = 0; i < m_all.size(); ++i)
            if (allowed(m_all.at(i))) m_visible.append(i);
        return;
    }

    QList<QPair<int, int>> scored;   // {score, index}
    for (int i = 0; i < m_all.size(); ++i) {
        const AppEntry& e = m_all.at(i);
        if (!allowed(e)) continue;

        const QString n = e.name.toLower();
        int score;
        if (n.startsWith(q)) score = 0;
        else if (n.contains(q)) score = 1;
        else if (e.genericName.toLower().contains(q)
                 || e.keywords.toLower().contains(q)
                 || e.comment.toLower().contains(q)) score = 2;
        else continue;
        scored.append({score, i});
    }

    std::stable_sort(scored.begin(), scored.end(),
                     [](const auto& a, const auto& b) { return a.first < b.first; });
    for (const auto& p : scored) m_visible.append(p.second);
}

void Applications::setQuery(const QString& query) {
    if (query == m_query) return;
    m_query = query;
    beginResetModel();
    filter();
    endResetModel();
    emit queryChanged();
    emit countChanged();
}

void Applications::setIncludeHidden(bool include) {
    if (include == m_includeHidden) return;
    m_includeHidden = include;
    beginResetModel();
    filter();
    endResetModel();
    emit includeHiddenChanged();
    emit countChanged();
}

void Applications::setIncludeTerminal(bool include) {
    if (include == m_includeTerminal) return;
    m_includeTerminal = include;
    beginResetModel();
    filter();
    endResetModel();
    emit includeTerminalChanged();
    emit countChanged();
}

void Applications::setExcludeCategories(const QStringList& categories) {
    if (categories == m_excludeCategories) return;
    m_excludeCategories = categories;
    beginResetModel();
    filter();
    endResetModel();
    emit excludeCategoriesChanged();
    emit countChanged();
}

void Applications::setExcludeNames(const QStringList& names) {
    if (names == m_excludeNames) return;
    m_excludeNames = names;
    beginResetModel();
    filter();
    endResetModel();
    emit excludeNamesChanged();
    emit countChanged();
}

void Applications::setTerminal(const QString& terminal) {
    if (terminal == m_terminal) return;
    m_terminal = terminal;
    emit terminalChanged();
}

int Applications::rowCount(const QModelIndex& parent) const {
    return parent.isValid() ? 0 : m_visible.size();
}

QHash<int, QByteArray> Applications::roleNames() const {
    return {
        {NameRole, "name"},
        {GenericNameRole, "genericName"},
        {CommentRole, "comment"},
        {IconRole, "icon"},
        {AppIdRole, "appId"},
        {ExecRole, "exec"},
        {CategoriesRole, "categories"},
        {TerminalRole, "terminal"},
        {NoDisplayRole, "noDisplay"},
    };
}

QVariant Applications::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_visible.size())
        return {};
    const AppEntry& e = m_all.at(m_visible.at(index.row()));
    switch (role) {
    case NameRole: return e.name;
    case GenericNameRole: return e.genericName;
    case CommentRole: return e.comment;
    case IconRole: return e.icon;
    case AppIdRole: return e.appId;
    case ExecRole: return e.exec;
    case CategoriesRole: return e.categories;
    case TerminalRole: return e.terminal;
    case NoDisplayRole: return e.noDisplay;
    }
    return {};
}

QVariantMap Applications::get(int row) const {
    if (row < 0 || row >= m_visible.size()) return {};
    const AppEntry& e = m_all.at(m_visible.at(row));
    return {
        {"name", e.name},
        {"genericName", e.genericName},
        {"comment", e.comment},
        {"icon", e.icon},
        {"appId", e.appId},
        {"exec", e.exec},
        {"categories", e.categories},
        {"terminal", e.terminal},
        {"noDisplay", e.noDisplay},
    };
}

bool Applications::launch(int row) {
    if (row < 0 || row >= m_visible.size()) return false;
    return run(m_all.at(m_visible.at(row)));
}

bool Applications::launchById(const QString& appId) {
    for (const AppEntry& e : std::as_const(m_all))
        if (e.appId == appId) return run(e);
    return false;
}

bool Applications::run(const AppEntry& entry) {
    QString cmd;
    for (int i = 0; i < entry.exec.size(); ++i) {
        if (entry.exec[i] == '%' && i + 1 < entry.exec.size()) {
            if (entry.exec[i + 1] == '%') cmd += '%';
            ++i;
            continue;
        }
        cmd += entry.exec[i];
    }

    QStringList args = QProcess::splitCommand(cmd.trimmed());
    if (args.isEmpty()) return false;

    if (entry.terminal) {
        args.prepend(QStringLiteral("-e"));
        args.prepend(m_terminal);
    }

    const QString program = args.takeFirst();
    return QProcess::startDetached(program, args);
}