#pragma once

#include <QFileSystemWatcher>
#include <QJsonObject>
#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class Config : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantMap data READ data NOTIFY dataChanged)           // defaults + your file
    Q_PROPERTY(QString path READ path CONSTANT)
    Q_PROPERTY(QString registryDir READ registryDir CONSTANT)
    Q_PROPERTY(QVariantList sections READ sections NOTIFY registryChanged)   // for the settings window
    Q_PROPERTY(QVariantList bindings READ bindings NOTIFY registryChanged)   // entries with "bind"

public:
    explicit Config(QObject* parent = nullptr);

    QVariantMap data() const { return m_data; }
    QString path() const { return m_path; }
    QString registryDir() const { return m_registryDir; }
    QVariantList sections() const { return m_sections; }
    QVariantList bindings() const { return m_bindings; }

    Q_INVOKABLE QVariant get(const QString& key) const;
    Q_INVOKABLE void set(const QString& key, const QVariant& value);
    Q_INVOKABLE void reset(const QString& key);
    Q_INVOKABLE void resetAll();                     // keeps a copy in iris.json.bak

signals:
    void dataChanged();
    void registryChanged();

private:
    void load();
    void loadRegistry();
    void rebuild();
    void scheduleSave();
    void save();
    void rewatch();
    void rewatchRegistry();

    QString m_path;
    QString m_registryDir;
    QJsonObject m_user;        // what is in iris.json
    QJsonObject m_defaults;    // built from the registry
    QJsonObject m_merged;
    QVariantMap m_data;
    QVariantList m_sections;
    QVariantList m_bindings;
    QByteArray m_lastWritten;

    QFileSystemWatcher m_watcher;
    QFileSystemWatcher m_regWatcher;
    QTimer m_reload;
    QTimer m_regReload;
    QTimer m_save;
};