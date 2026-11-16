#include "Wallpapers.h"

#include <algorithm>
#include <cmath>

#include <QCryptographicHash>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QImageReader>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocalSocket>
#include <QPointer>
#include <QProcess>
#include <QRunnable>
#include <QSaveFile>
#include <QThreadPool>
#include <QUrl>

namespace {

QString expand(const QString& p) {
    if (p == QLatin1String("~")) return QDir::homePath();
    if (p.startsWith(QLatin1String("~/"))) return QDir::homePath() + p.mid(1);
    return p;
}

QString stateDir() {
    return qEnvironmentVariable("XDG_STATE_HOME", QDir::homePath() + QStringLiteral("/.local/state"))
           + QStringLiteral("/iris");
}
QString statePath() { return stateDir() + QStringLiteral("/wallpaper"); }
QString favoritesPath() { return stateDir() + QStringLiteral("/favorites.json"); }
QString cacheDir() {
    return qEnvironmentVariable("XDG_CACHE_HOME", QDir::homePath() + QStringLiteral("/.cache"))
           + QStringLiteral("/iris/wallpapers");
}

QByteArray hyprRequest(const QByteArray& cmd) {
    const QString sig = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");
    const QString run = qEnvironmentVariable("XDG_RUNTIME_DIR");
    if (sig.isEmpty() || run.isEmpty()) return {};

    QLocalSocket s;
    s.connectToServer(run + QStringLiteral("/hypr/") + sig + QStringLiteral("/.socket.sock"));
    if (!s.waitForConnected(300)) return {};
    s.write(cmd);
    s.waitForBytesWritten(300);

    QByteArray out;
    while (s.waitForReadyRead(300)) out += s.readAll();
    out += s.readAll();
    return out;
}

QColor dominantOf(const QImage& src) {
    const QImage s = src.scaled(24, 24, Qt::IgnoreAspectRatio, Qt::SmoothTransformation)
                         .convertToFormat(QImage::Format_RGB32);
    double r = 0, g = 0, b = 0, sum = 0;
    for (int y = 0; y < s.height(); ++y) {
        for (int x = 0; x < s.width(); ++x) {
            const QColor c(s.pixel(x, y));
            const double w = 0.05 + c.hsvSaturationF() * c.hsvSaturationF() * c.valueF();
            r += c.redF() * w;
            g += c.greenF() * w;
            b += c.blueF() * w;
            sum += w;
        }
    }
    return sum > 0 ? QColor::fromRgbF(float(r / sum), float(g / sum), float(b / sum)) : QColor("#808080");
}

QString thumbKey(const QFileInfo& info) {
    const QByteArray raw = (info.absoluteFilePath() + QLatin1Char('|')
                            + QString::number(info.lastModified().toSecsSinceEpoch()) + QLatin1Char('|')
                            + QString::number(info.size())).toUtf8();
    return QString::fromLatin1(QCryptographicHash::hash(raw, QCryptographicHash::Sha1).toHex().left(16));
}

class ThumbJob : public QRunnable {
public:
    ThumbJob(Wallpapers* owner, QString path, QString key, QString dir)
        : m_owner(owner), m_path(std::move(path)), m_key(std::move(key)), m_dir(std::move(dir)) {}

    void run() override {
        QImageReader reader(m_path);
        reader.setAutoTransform(true);
        const QSize size = reader.size();
        if (!size.isValid()) return;

        QSize target = size;
        target.scale(480, 270, Qt::KeepAspectRatioByExpanding);
        reader.setScaledSize(target);                    // JPEG decodes at the small size directly
        QImage img = reader.read();
        if (img.isNull()) return;

        const int cw = qMin(img.width(), img.height() * 16 / 9);
        const int ch = qMin(img.height(), img.width() * 9 / 16);
        img = img.copy((img.width() - cw) / 2, (img.height() - ch) / 2, cw, ch);

        const QColor dom = dominantOf(img);
        const QString file = m_dir + QLatin1Char('/') + m_key + QLatin1Char('-') + dom.name().mid(1)
                             + QStringLiteral(".jpg");
        QDir().mkpath(m_dir);
        if (!img.save(file, "JPEG", 85)) return;

        QPointer<Wallpapers> owner = m_owner;
        const QString path = m_path;
        QMetaObject::invokeMethod(m_owner, [owner, path, file, dom] {
            if (owner) owner->thumbDone(path, file, dom);
        }, Qt::QueuedConnection);
    }

private:
    Wallpapers* m_owner;
    QString m_path, m_key, m_dir;
};

}  // namespace

Wallpapers::Wallpapers(QObject* parent) : QAbstractListModel(parent) {
    m_folder = QDir::homePath() + QStringLiteral("/Pictures/Wallpapers");
    m_applyScript = QString();

    QFile f(statePath());
    if (f.open(QIODevice::ReadOnly)) m_current = QString::fromUtf8(f.readAll()).trimmed();
    loadFavorites();

    m_debounce.setSingleShot(true);
    m_debounce.setInterval(400);
    connect(&m_debounce, &QTimer::timeout, this, &Wallpapers::reload);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, &m_debounce, qOverload<>(&QTimer::start));

    reload();
}

Wallpapers::~Wallpapers() {
    QThreadPool::globalInstance()->clear();
    QThreadPool::globalInstance()->waitForDone(3000);
}


void Wallpapers::reload() {
    const QString dir = expand(m_folder);

    if (!m_watcher.directories().isEmpty()) m_watcher.removePaths(m_watcher.directories());
    if (QDir(dir).exists()) {
        m_watcher.addPath(dir);
        for (const QString& sub : QDir(dir).entryList(QDir::Dirs | QDir::NoDotAndDotDot))
            m_watcher.addPath(dir + QLatin1Char('/') + sub);
    }

    const QString cdir = cacheDir();
    QHash<QString, QString> cached;
    for (const QString& f : QDir(cdir).entryList({QStringLiteral("*.jpg")}, QDir::Files))
        if (f.size() >= 24) cached.insert(f.left(16), f);

    static const QSet<QString> exts = {"png", "jpg", "jpeg", "webp"};
    QList<WallpaperEntry> list;
    QList<QPair<QString, QString>> jobs;                          // path, key

    QDirIterator it(dir, QDir::Files, QDirIterator::Subdirectories | QDirIterator::FollowSymlinks);
    while (it.hasNext()) {
        const QFileInfo info(it.next());
        if (!exts.contains(info.suffix().toLower())) continue;

        WallpaperEntry e;
        e.name = info.completeBaseName();
        e.path = info.absoluteFilePath();
        e.url = QUrl::fromLocalFile(e.path).toString();

        const QString rel = QDir(dir).relativeFilePath(e.path);
        const int slash = rel.indexOf(QLatin1Char('/'));
        e.category = slash > 0 ? rel.left(slash) : QString();

        const QString key = thumbKey(info);
        const auto hit = cached.constFind(key);
        if (hit != cached.constEnd()) {
            e.thumb = cdir + QLatin1Char('/') + hit.value();
            e.dominant = QColor(QStringLiteral("#") + hit.value().mid(17, 6));
        } else {
            jobs.append({e.path, key});
        }
        list.append(e);
    }

    std::sort(list.begin(), list.end(), [](const WallpaperEntry& a, const WallpaperEntry& b) {
        return a.name.compare(b.name, Qt::CaseInsensitive) < 0;
    });

    QSet<QString> cats;
    for (const WallpaperEntry& e : std::as_const(list))
        if (!e.category.isEmpty()) cats.insert(e.category);
    QStringList catList(cats.begin(), cats.end());
    catList.sort(Qt::CaseInsensitive);

    beginResetModel();
    m_all = list;
    filter();
    endResetModel();

    if (catList != m_categories) { m_categories = catList; emit categoriesChanged(); }
    emit countChanged();
    ++m_revision;
    emit revisionChanged();

    QThreadPool::globalInstance()->clear();                       // drop thumbnails of an older scan
    for (const auto& j : std::as_const(jobs))
        QThreadPool::globalInstance()->start(new ThumbJob(this, j.first, j.second, cdir), -1);   // low priority
}

void Wallpapers::thumbDone(const QString& path, const QString& file, const QColor& dominant) {
    for (int i = 0; i < m_all.size(); ++i) {
        if (m_all[i].path != path) continue;
        m_all[i].thumb = file;
        m_all[i].dominant = dominant;
        const int row = m_visible.indexOf(i);
        if (row >= 0) emit dataChanged(index(row), index(row));
        break;
    }
    ++m_revision;
    emit revisionChanged();
}


void Wallpapers::filter() {
    m_visible.clear();
    const QString q = m_query.trimmed().toLower();
    for (int i = 0; i < m_all.size(); ++i) {
        const WallpaperEntry& e = m_all.at(i);
        if (m_favoritesOnly && !m_favorites.contains(e.path)) continue;
        if (!m_category.isEmpty() && e.category != m_category) continue;
        if (!q.isEmpty() && !e.name.toLower().contains(q) && !e.category.toLower().contains(q)) continue;
        m_visible.append(i);
    }
}

void Wallpapers::refilter() {
    beginResetModel();
    filter();
    endResetModel();
    emit countChanged();
}

void Wallpapers::setQuery(const QString& q) {
    if (q == m_query) return;
    m_query = q;
    emit queryChanged();
    refilter();
}
void Wallpapers::setCategory(const QString& c) {
    if (c == m_category) return;
    m_category = c;
    emit categoryChanged();
    refilter();
}
void Wallpapers::setFavoritesOnly(bool on) {
    if (on == m_favoritesOnly) return;
    m_favoritesOnly = on;
    emit favoritesOnlyChanged();
    refilter();
}

void Wallpapers::setFolder(const QString& folder) {
    if (folder == m_folder) return;
    m_folder = folder;
    emit folderChanged();
    reload();
}
void Wallpapers::setApplyScript(const QString& script) {
    if (script == m_applyScript) return;
    m_applyScript = script;
    emit applyScriptChanged();
}


void Wallpapers::loadFavorites() {
    QFile f(favoritesPath());
    if (!f.open(QIODevice::ReadOnly)) return;
    for (const QJsonValue& v : QJsonDocument::fromJson(f.readAll()).array()) m_favorites.insert(v.toString());
}

void Wallpapers::saveFavorites() const {
    QJsonArray a;
    for (const QString& p : m_favorites) a.append(p);
    QDir().mkpath(stateDir());
    QSaveFile f(favoritesPath());
    if (f.open(QIODevice::WriteOnly)) {
        f.write(QJsonDocument(a).toJson(QJsonDocument::Compact));
        f.commit();
    }
}

void Wallpapers::toggleFavorite(const QString& path) {
    if (m_favorites.contains(path)) m_favorites.remove(path);
    else m_favorites.insert(path);
    saveFavorites();

    if (m_favoritesOnly) {
        refilter();
    } else {
        for (int row = 0; row < m_visible.size(); ++row)
            if (m_all.at(m_visible.at(row)).path == path) emit dataChanged(index(row), index(row));
    }
    ++m_revision;
    emit revisionChanged();
}


int Wallpapers::rowCount(const QModelIndex& parent) const {
    return parent.isValid() ? 0 : m_visible.size();
}

QHash<int, QByteArray> Wallpapers::roleNames() const {
    return {{NameRole, "name"}, {PathRole, "path"}, {UrlRole, "url"}, {ThumbRole, "thumb"},
            {CategoryRole, "category"}, {DominantRole, "dominant"}, {FavoriteRole, "favorite"}};
}

QVariantMap Wallpapers::toMap(const WallpaperEntry& e) const {
    return {
        {"name", e.name},
        {"path", e.path},
        {"url", e.url},
        {"thumb", e.thumb.isEmpty() ? e.url : QUrl::fromLocalFile(e.thumb).toString()},
        {"category", e.category},
        {"dominant", e.dominant.isValid() ? e.dominant : QColor(Qt::transparent)},
        {"favorite", m_favorites.contains(e.path)},
    };
}

QVariant Wallpapers::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_visible.size()) return {};
    const QVariantMap m = toMap(m_all.at(m_visible.at(index.row())));
    switch (role) {
    case NameRole: return m.value("name");
    case PathRole: return m.value("path");
    case UrlRole: return m.value("url");
    case ThumbRole: return m.value("thumb");
    case CategoryRole: return m.value("category");
    case DominantRole: return m.value("dominant");
    case FavoriteRole: return m.value("favorite");
    }
    return {};
}

QVariantMap Wallpapers::get(int row) const {
    if (row < 0 || row >= m_visible.size()) return {};
    return toMap(m_all.at(m_visible.at(row)));
}


QVariantMap Wallpapers::cursor() const {
    const QJsonObject c = QJsonDocument::fromJson(hyprRequest("j/cursorpos")).object();
    const QJsonArray mons = QJsonDocument::fromJson(hyprRequest("j/monitors")).array();
    if (c.isEmpty() || mons.isEmpty()) return {{"ok", false}};

    const qreal gx = c.value("x").toDouble();
    const qreal gy = c.value("y").toDouble();

    QJsonObject found;
    for (const QJsonValue& v : mons) {
        const QJsonObject m = v.toObject();
        const qreal scale = m.value("scale").toDouble(1.0);
        const bool rot = m.value("transform").toInt() % 2 == 1;
        const qreal w = (rot ? m.value("height") : m.value("width")).toDouble() / scale;
        const qreal h = (rot ? m.value("width") : m.value("height")).toDouble() / scale;
        const qreal x = m.value("x").toDouble();
        const qreal y = m.value("y").toDouble();
        if (gx >= x && gx < x + w && gy >= y && gy < y + h) { found = m; break; }
    }
    if (found.isEmpty()) {
        for (const QJsonValue& v : mons)
            if (v.toObject().value("focused").toBool()) { found = v.toObject(); break; }
        if (found.isEmpty()) found = mons.first().toObject();
    }

    return {{"ok", true},
            {"monitor", found.value("name").toString()},
            {"x", gx - found.value("x").toDouble()},
            {"y", gy - found.value("y").toDouble()}};
}

QVariantList Wallpapers::ringSlots(qreal cx, qreal cy, qreal w, qreal h, qreal tileW, qreal tileH) const {
    struct Ring { qreal r; int n; };
    const Ring rings[] = {{190, 7}, {330, 12}, {470, 17}};
    const qreal s = qMax(tileW / 150.0, tileH / 84.0 * 0.85);
    const qreal mx = tileW / 2 + 12;
    const qreal my = tileH / 2 + 12;
    const qreal pi = 3.14159265358979323846;

    QVariantList out;
    for (const Ring& ring : rings) {
        for (int i = 0; i < ring.n; ++i) {
            const qreal a = -pi / 2 + i * 2 * pi / ring.n;
            const qreal x = cx + std::cos(a) * ring.r * s;
            const qreal y = cy + std::sin(a) * ring.r * s * 0.8;
            if (x >= mx && x <= w - mx && y >= my && y <= h - my)
                out.append(QVariantMap{{"x", x}, {"y", y}});
        }
    }
    return out;
}

void Wallpapers::apply(const QString& path) {
    m_current = path;
    emit currentChanged();
    QDir().mkpath(stateDir());
    QFile f(statePath());
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) f.write(path.toUtf8());

    if (!m_applyScript.trimmed().isEmpty())
        QProcess::startDetached(QStringLiteral("sh"),
                                {QStringLiteral("-c"), m_applyScript, QStringLiteral("sh"), path});
    emit applied(path);
}