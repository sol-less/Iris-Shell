#pragma once

#include <QColor>
#include <QFileSystemWatcher>
#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

#define MD3_COLORS(X) \
    X(background, "background") \
    X(error, "error") \
    X(errorContainer, "error_container") \
    X(inverseOnSurface, "inverse_on_surface") \
    X(inversePrimary, "inverse_primary") \
    X(inverseSurface, "inverse_surface") \
    X(onBackground, "on_background") \
    X(onError, "on_error") \
    X(onErrorContainer, "on_error_container") \
    X(onPrimary, "on_primary") \
    X(onPrimaryContainer, "on_primary_container") \
    X(onPrimaryFixed, "on_primary_fixed") \
    X(onPrimaryFixedVariant, "on_primary_fixed_variant") \
    X(onSecondary, "on_secondary") \
    X(onSecondaryContainer, "on_secondary_container") \
    X(onSecondaryFixed, "on_secondary_fixed") \
    X(onSecondaryFixedVariant, "on_secondary_fixed_variant") \
    X(onSurface, "on_surface") \
    X(onSurfaceVariant, "on_surface_variant") \
    X(onTertiary, "on_tertiary") \
    X(onTertiaryContainer, "on_tertiary_container") \
    X(onTertiaryFixed, "on_tertiary_fixed") \
    X(onTertiaryFixedVariant, "on_tertiary_fixed_variant") \
    X(outline, "outline") \
    X(outlineVariant, "outline_variant") \
    X(primary, "primary") \
    X(primaryContainer, "primary_container") \
    X(primaryFixed, "primary_fixed") \
    X(primaryFixedDim, "primary_fixed_dim") \
    X(scrim, "scrim") \
    X(secondary, "secondary") \
    X(secondaryContainer, "secondary_container") \
    X(secondaryFixed, "secondary_fixed") \
    X(secondaryFixedDim, "secondary_fixed_dim") \
    X(shadow, "shadow") \
    X(sourceColor, "source_color") \
    X(surface, "surface") \
    X(surfaceBright, "surface_bright") \
    X(surfaceContainer, "surface_container") \
    X(surfaceContainerHigh, "surface_container_high") \
    X(surfaceContainerHighest, "surface_container_highest") \
    X(surfaceContainerLow, "surface_container_low") \
    X(surfaceContainerLowest, "surface_container_lowest") \
    X(surfaceDim, "surface_dim") \
    X(surfaceTint, "surface_tint") \
    X(surfaceVariant, "surface_variant") \
    X(tertiary, "tertiary") \
    X(tertiaryContainer, "tertiary_container") \
    X(tertiaryFixed, "tertiary_fixed") \
    X(tertiaryFixedDim, "tertiary_fixed_dim")

class Theme : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_ATTACHED(Theme)

    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(QString section READ section WRITE setSection NOTIFY sectionChanged)
    Q_PROPERTY(bool loaded READ loaded NOTIFY loadedChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorStringChanged)

#define X(name, key) Q_PROPERTY(QColor name READ name NOTIFY colorsChanged)
    MD3_COLORS(X)
#undef X

public:
    explicit Theme(QObject* parent = nullptr);

    static Theme* instance();

    static Theme* qmlAttachedProperties(QObject*) { return instance(); }

    QString path() const { return instance()->m_path; }
    void setPath(const QString& path);

    QString section() const { return instance()->m_section; }
    void setSection(const QString& section);

    bool loaded() const { return instance()->m_loaded; }
    QString errorString() const { return instance()->m_errorString; }

#define X(name, key) QColor name() const { return instance()->m_##name; }
    MD3_COLORS(X)
#undef X

signals:
    void pathChanged();
    void sectionChanged();
    void loadedChanged();
    void errorStringChanged();
    void colorsChanged();

private:
    struct SharedTag {};
    Theme(QObject* parent, SharedTag);

    static QString resolvePath(const QString& path);
    void rewatch();
    void reload();
    void setStatus(bool loaded, const QString& error);

    bool m_shared = false;

    QString m_path;
    QString m_resolved;
    QString m_section = QStringLiteral("md3");
    bool m_loaded = false;
    QString m_errorString;

    QFileSystemWatcher m_watcher;
    QTimer m_debounce;

#define X(name, key) QColor m_##name = Qt::transparent;
    MD3_COLORS(X)
#undef X
};