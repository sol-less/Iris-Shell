#pragma once

#include <QAbstractListModel>
#include <QColor>
#include <QFileSystemWatcher>
#include <QSet>
#include <QStringList>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

struct WallpaperEntry {
    QString name;
    QString path;
    QString url;
    QString category;       // the top-level sub-folder, empty for files in the root
    QString thumb;          // cached thumbnail file, empty until it exists
    QColor dominant;        // invalid until the thumbnail exists
};

class Wallpapers : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString folder READ folder WRITE setFolder NOTIFY folderChanged)
    Q_PROPERTY(QString applyScript READ applyScript WRITE setApplyScript NOTIFY applyScriptChanged)
    Q_PROPERTY(QString current READ current NOTIFY currentChanged)
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(QString category READ category WRITE setCategory NOTIFY categoryChanged)     // "" = all
    Q_PROPERTY(bool favoritesOnly READ favoritesOnly WRITE setFavoritesOnly NOTIFY favoritesOnlyChanged)
    Q_PROPERTY(QStringList categories READ categories NOTIFY categoriesChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)               // shown, after the filters
    Q_PROPERTY(int total READ total NOTIFY countChanged)               // all wallpapers
    Q_PROPERTY(int revision READ revision NOTIFY revisionChanged)      // bumps when thumbnails or favorites change

public:
    enum Role { NameRole = Qt::UserRole + 1, PathRole, UrlRole, ThumbRole, CategoryRole, DominantRole, FavoriteRole };

    explicit Wallpapers(QObject* parent = nullptr);
    ~Wallpapers() override;

    int rowCount(const QModelIndex& parent = {}) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString folder() const { return m_folder; }
    void setFolder(const QString& folder);
    QString applyScript() const { return m_applyScript; }
    void setApplyScript(const QString& script);
    QString current() const { return m_current; }

    QString query() const { return m_query; }
    void setQuery(const QString& q);
    QString category() const { return m_category; }
    void setCategory(const QString& c);
    bool favoritesOnly() const { return m_favoritesOnly; }
    void setFavoritesOnly(bool on);
    QStringList categories() const { return m_categories; }

    int count() const { return m_visible.size(); }
    int total() const { return m_all.size(); }
    int revision() const { return m_revision; }

    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE QVariantMap cursor() const;       // {ok, monitor, x, y}, local to the monitor (Hyprland)
    Q_INVOKABLE QVariantList ringSlots(qreal cx, qreal cy, qreal w, qreal h, qreal tileW, qreal tileH) const;
    Q_INVOKABLE void apply(const QString& path);
    Q_INVOKABLE void reload();
    Q_INVOKABLE void toggleFavorite(const QString& path);

    void thumbDone(const QString& path, const QString& file, const QColor& dominant);

signals:
    void folderChanged();
    void applyScriptChanged();
    void currentChanged();
    void queryChanged();
    void categoryChanged();
    void favoritesOnlyChanged();
    void categoriesChanged();
    void countChanged();
    void revisionChanged();
    void applied(const QString& path);

private:
    void filter();
    void refilter();
    void loadFavorites();
    void saveFavorites() const;
    QVariantMap toMap(const WallpaperEntry& e) const;

    QString m_folder;
    QString m_applyScript;
    QString m_current;
    QString m_query;
    QString m_category;
    bool m_favoritesOnly = false;
    int m_revision = 0;

    QList<WallpaperEntry> m_all;
    QList<int> m_visible;                  // indices into m_all
    QStringList m_categories;
    QSet<QString> m_favorites;

    QFileSystemWatcher m_watcher;
    QTimer m_debounce;
};