#pragma once

#include <QAbstractListModel>
#include <QFileSystemWatcher>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

struct AppEntry {
    QString appId;
    QString name;
    QString genericName;
    QString comment;
    QString icon;
    QString exec;
    QString keywords;
    QStringList categories;
    bool terminal = false;
    bool noDisplay = false;
};

class Applications : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(QString terminal READ terminal WRITE setTerminal NOTIFY terminalChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool includeHidden READ includeHidden WRITE setIncludeHidden NOTIFY includeHiddenChanged)
    Q_PROPERTY(bool includeTerminal READ includeTerminal WRITE setIncludeTerminal NOTIFY includeTerminalChanged)
    Q_PROPERTY(QStringList excludeCategories READ excludeCategories WRITE setExcludeCategories NOTIFY excludeCategoriesChanged)
    Q_PROPERTY(QStringList excludeNames READ excludeNames WRITE setExcludeNames NOTIFY excludeNamesChanged)

public:
    enum Role {
        NameRole = Qt::UserRole + 1,
        GenericNameRole,
        CommentRole,
        IconRole,
        AppIdRole,
        ExecRole,
        CategoriesRole,
        TerminalRole,
        NoDisplayRole,
    };

    explicit Applications(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = {}) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString query() const { return m_query; }
    void setQuery(const QString& query);

    QString terminal() const { return m_terminal; }
    void setTerminal(const QString& terminal);

    QStringList excludeCategories() const { return m_excludeCategories; }
    void setExcludeCategories(const QStringList& categories);

    QStringList excludeNames() const { return m_excludeNames; }
    void setExcludeNames(const QStringList& names);

    int count() const { return m_visible.size(); }

    bool includeHidden() const { return m_includeHidden; }
    void setIncludeHidden(bool include);

    bool includeTerminal() const { return m_includeTerminal; }
    void setIncludeTerminal(bool include);

    Q_INVOKABLE bool launch(int row);
    Q_INVOKABLE bool launchById(const QString& appId);
    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE void reload();

signals:
    void queryChanged();
    void terminalChanged();
    void countChanged();
    void includeHiddenChanged();
    void includeTerminalChanged();
    void excludeCategoriesChanged();
    void excludeNamesChanged();

private:
    static QStringList searchDirs();
    void rescan();
    void rewatch();
    void filter();
    bool run(const AppEntry& entry);

    QList<AppEntry> m_all;
    QList<int> m_visible;
    QStringList m_excludeCategories;
    QStringList m_excludeNames;
    QString m_query;
    QString m_terminal;
    bool m_includeHidden = false;
    bool m_includeTerminal = false;

    QFileSystemWatcher m_watcher;
    QTimer m_debounce;
};