#include "Wallpapers.h"

#include <cmath>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocalSocket>
#include <QProcess>
#include <QSet>
#include <QUrl>

static QString statePath() {
  return qEnvironmentVariable("XDG_STATE_HOME",
                              QDir::homePath() +
                                  QStringLiteral("/.local/state")) +
         QStringLiteral("/iris/wallpaper");
}

static QString expand(const QString &p) {
  if (p == QLatin1String("~"))
    return QDir::homePath();
  if (p.startsWith(QLatin1String("~/")))
    return QDir::homePath() + p.mid(1);
  return p;
}

// one request over Hyprland's socket ("j/..." = JSON); the server closes after
// replying
static QByteArray hyprRequest(const QByteArray &cmd) {
  const QString sig = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");
  const QString run = qEnvironmentVariable("XDG_RUNTIME_DIR");
  if (sig.isEmpty() || run.isEmpty())
    return {};

  QLocalSocket s;
  s.connectToServer(run + QStringLiteral("/hypr/") + sig +
                    QStringLiteral("/.socket.sock"));
  if (!s.waitForConnected(300))
    return {};
  s.write(cmd);
  s.waitForBytesWritten(300);

  QByteArray out;
  while (s.waitForReadyRead(300))
    out += s.readAll();
  out += s.readAll();
  return out;
}

Wallpapers::Wallpapers(QObject *parent) : QAbstractListModel(parent) {
  m_folder = QDir::homePath() + QStringLiteral("/Pictures/Wallpapers");
  // "$1" is the chosen image; edit to match your wallpaper tool
  m_applyScript =
      QStringLiteral("matugen image \"$1\" --source-color-index 0 </dev/null");

  m_debounce.setSingleShot(true);
  m_debounce.setInterval(300);
  connect(&m_debounce, &QTimer::timeout, this, &Wallpapers::reload);
  connect(&m_watcher, &QFileSystemWatcher::directoryChanged, &m_debounce,
          qOverload<>(&QTimer::start));

  reload();
  QFile f(statePath());
  if (f.open(QIODevice::ReadOnly))
    m_current = QString::fromUtf8(f.readAll()).trimmed();
}

void Wallpapers::setFolder(const QString &folder) {
  if (folder == m_folder)
    return;
  m_folder = folder;
  emit folderChanged();
  reload();
}

void Wallpapers::setApplyScript(const QString &script) {
  if (script == m_applyScript)
    return;
  m_applyScript = script;
  emit applyScriptChanged();
}

void Wallpapers::reload() {
  const QString dir = expand(m_folder);

  if (!m_watcher.directories().isEmpty())
    m_watcher.removePaths(m_watcher.directories());
  if (QDir(dir).exists())
    m_watcher.addPath(dir);

  static const QSet<QString> exts = {"png", "jpg", "jpeg", "webp"};
  QList<WallpaperEntry> list;
  const auto infos =
      QDir(dir).entryInfoList(QDir::Files, QDir::Name | QDir::IgnoreCase);
  for (const QFileInfo &info : infos) {
    if (!exts.contains(info.suffix().toLower()))
      continue;
    list.append({info.completeBaseName(), info.absoluteFilePath(),
                 QUrl::fromLocalFile(info.absoluteFilePath()).toString()});
  }

  beginResetModel();
  m_items = list;
  endResetModel();
  emit countChanged();
}

int Wallpapers::rowCount(const QModelIndex &parent) const {
  return parent.isValid() ? 0 : m_items.size();
}

QHash<int, QByteArray> Wallpapers::roleNames() const {
  return {{NameRole, "name"}, {PathRole, "path"}, {UrlRole, "url"}};
}

QVariant Wallpapers::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
    return {};
  const WallpaperEntry &e = m_items.at(index.row());
  switch (role) {
  case NameRole:
    return e.name;
  case PathRole:
    return e.path;
  case UrlRole:
    return e.url;
  }
  return {};
}

QVariantMap Wallpapers::get(int row) const {
  if (row < 0 || row >= m_items.size())
    return {};
  const WallpaperEntry &e = m_items.at(row);
  return {{"name", e.name}, {"path", e.path}, {"url", e.url}};
}

QVariantMap Wallpapers::cursor() const {
  const QJsonObject c =
      QJsonDocument::fromJson(hyprRequest("j/cursorpos")).object();
  const QJsonArray mons =
      QJsonDocument::fromJson(hyprRequest("j/monitors")).array();
  if (c.isEmpty() || mons.isEmpty())
    return {{"ok", false}};

  const qreal gx = c.value("x").toDouble();
  const qreal gy = c.value("y").toDouble();

  QJsonObject found;
  for (const QJsonValue &v : mons) {
    const QJsonObject m = v.toObject();
    const qreal scale = m.value("scale").toDouble(1.0);
    const bool rot = m.value("transform").toInt() % 2 == 1;
    const qreal w =
        (rot ? m.value("height") : m.value("width")).toDouble() / scale;
    const qreal h =
        (rot ? m.value("width") : m.value("height")).toDouble() / scale;
    const qreal x = m.value("x").toDouble();
    const qreal y = m.value("y").toDouble();
    if (gx >= x && gx < x + w && gy >= y && gy < y + h) {
      found = m;
      break;
    }
  }
  if (found.isEmpty()) {
    for (const QJsonValue &v : mons)
      if (v.toObject().value("focused").toBool()) {
        found = v.toObject();
        break;
      }
    if (found.isEmpty())
      found = mons.first().toObject();
  }

  return {{"ok", true},
          {"monitor", found.value("name").toString()},
          {"x", gx - found.value("x").toDouble()},
          {"y", gy - found.value("y").toDouble()}};
}

QVariantList Wallpapers::ringSlots(qreal cx, qreal cy, qreal w, qreal h,
                                   qreal tileW, qreal tileH) const {
  struct Ring {
    qreal r;
    int n;
  };
  const Ring rings[] = {{190, 7}, {330, 12}, {470, 17}};
  const qreal s = tileW / 150.0; // rings grow with the tile size
  const qreal mx = tileW / 2 + 12;
  const qreal my = tileH / 2 + 12;
  const qreal pi = 3.14159265358979323846;

  QVariantList out;
  for (const Ring &ring : rings) {
    for (int i = 0; i < ring.n; ++i) {
      const qreal a = -pi / 2 + i * 2 * pi / ring.n;
      const qreal x = cx + std::cos(a) * ring.r * s;
      const qreal y = cy + std::sin(a) * ring.r * s * 0.8; // screens are wide
      if (x >= mx && x <= w - mx && y >= my && y <= h - my)
        out.append(QVariantMap{{"x", x}, {"y", y}});
    }
  }
  return out;
}

void Wallpapers::apply(const QString &path) {
  m_current = path;
  emit currentChanged();
  QDir().mkpath(QFileInfo(statePath()).absolutePath());
  QFile f(statePath());
  if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
    f.write(path.toUtf8());

  QProcess::startDetached(
      QStringLiteral("sh"),
      {QStringLiteral("-c"), m_applyScript, QStringLiteral("sh"), path});
  emit applied(path);
}