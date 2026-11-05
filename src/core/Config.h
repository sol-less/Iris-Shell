#pragma once

#include <QFileSystemWatcher>
#include <QJsonObject>
#include <QObject>
#include <QTimer>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class Config : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // defaults merged with the file; read it in a binding (Config.data.osd.squiggle) to stay reactive
    Q_PROPERTY(QVariantMap data READ data NOTIFY dataChanged)
    Q_PROPERTY(QString path READ path CONSTANT)

public:
    explicit Config(QObject* parent = nullptr);

    QVariantMap data() const { return m_data; }
    QString path() const { return m_path; }

    Q_INVOKABLE QVariant get(const QString& key) const;            // "osd.squiggle"
    Q_INVOKABLE void set(const QString& key, const QVariant& value);
    Q_INVOKABLE void reset(const QString& key);                    // back to the default
    Q_INVOKABLE void resetAll();

signals:
    void dataChanged();

private:
    void load();
    void rebuild();
    void scheduleSave();
    void save();
    void rewatch();

    QString m_path;
    QJsonObject m_user;        // what is in the file
    QJsonObject m_merged;      // defaults + user
    QVariantMap m_data;
    QByteArray m_lastWritten;

    QFileSystemWatcher m_watcher;
    QTimer m_reload;
    QTimer m_save;
};