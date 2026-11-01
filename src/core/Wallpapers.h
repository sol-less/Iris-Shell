#pragma once

#include <QAbstractListModel>
#include <QFileSystemWatcher>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

struct WallpaperEntry {
    QString name;   // file name without extension
    QString path;
    QString url;
};

class Wallpapers : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString folder READ folder WRITE setFolder NOTIFY folderChanged)
    Q_PROPERTY(QString applyScript READ applyScript WRITE setApplyScript NOTIFY applyScriptChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString current READ current NOTIFY currentChanged)
    QString current() const { return m_current; }

public:
    enum Role { NameRole = Qt::UserRole + 1, PathRole, UrlRole };

    explicit Wallpapers(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = {}) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString folder() const { return m_folder; }
    void setFolder(const QString& folder);
    QString applyScript() const { return m_applyScript; }
    void setApplyScript(const QString& script);
    int count() const { return m_items.size(); }

    Q_INVOKABLE QVariantMap get(int row) const;
    // {ok, monitor, x, y}: the cursor, local to the monitor it is on (Hyprland)
    Q_INVOKABLE QVariantMap cursor() const;
    // positions on rings around (cx, cy) that fit inside w x h
    Q_INVOKABLE QVariantList ringSlots(qreal cx, qreal cy, qreal w, qreal h, qreal tileW, qreal tileH) const;
    Q_INVOKABLE void apply(const QString& path);
    Q_INVOKABLE void reload();

signals:
    void folderChanged();
    void applyScriptChanged();
    void countChanged();
    void applied(const QString& path);
    void currentChanged();

private:
    QString m_folder;
    QString m_applyScript;
    QList<WallpaperEntry> m_items;
    QFileSystemWatcher m_watcher;
    QTimer m_debounce;
    QString m_current;
};