#pragma once

#include <QColor>
#include <QElapsedTimer>
#include <QList>
#include <QMetaObject>
#include <QQuickPaintedItem>
#include <QtQml/qqmlregistration.h>

class Equalizer : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QList<qreal> values READ values WRITE setValues NOTIFY valuesChanged)       // 0 to 1 per bar
    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)
    Q_PROPERTY(qreal barWidth READ barWidth WRITE setBarWidth NOTIFY barWidthChanged)
    Q_PROPERTY(qreal spacing READ spacing WRITE setSpacing NOTIFY spacingChanged)
    Q_PROPERTY(qreal radius READ radius WRITE setRadius NOTIFY radiusChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)                 // the foot of the bar
    Q_PROPERTY(QColor colorTop READ colorTop WRITE setColorTop NOTIFY colorTopChanged)     // the tip, and the peak dots
    Q_PROPERTY(bool mirror READ mirror WRITE setMirror NOTIFY mirrorChanged)               // bars grow from the middle
    Q_PROPERTY(bool peaks READ peaks WRITE setPeaks NOTIFY peaksChanged)
    Q_PROPERTY(qreal attackMs READ attackMs WRITE setAttackMs NOTIFY attackMsChanged)
    Q_PROPERTY(qreal releaseMs READ releaseMs WRITE setReleaseMs NOTIFY releaseMsChanged)

public:
    explicit Equalizer(QQuickItem* parent = nullptr) : QQuickPaintedItem(parent) { m_clock.start(); }

    void paint(QPainter* painter) override;

    QList<qreal> values() const { return m_values; }
    void setValues(const QList<qreal>& v) { m_values = v; update(); emit valuesChanged(); }   // wakes the animation up
    bool running() const { return m_running; }
    void setRunning(bool v) { if (v == m_running) return; m_running = v; m_last = -1; update(); emit runningChanged(); }
    qreal barWidth() const { return m_barWidth; }
    void setBarWidth(qreal v) { if (v == m_barWidth) return; m_barWidth = v; update(); emit barWidthChanged(); }
    qreal spacing() const { return m_spacing; }
    void setSpacing(qreal v) { if (v == m_spacing) return; m_spacing = v; update(); emit spacingChanged(); }
    qreal radius() const { return m_radius; }
    void setRadius(qreal v) { if (v == m_radius) return; m_radius = v; update(); emit radiusChanged(); }
    QColor color() const { return m_color; }
    void setColor(const QColor& v) { if (v == m_color) return; m_color = v; update(); emit colorChanged(); }
    QColor colorTop() const { return m_colorTop; }
    void setColorTop(const QColor& v) { if (v == m_colorTop) return; m_colorTop = v; update(); emit colorTopChanged(); }
    bool mirror() const { return m_mirror; }
    void setMirror(bool v) { if (v == m_mirror) return; m_mirror = v; update(); emit mirrorChanged(); }
    bool peaks() const { return m_peaks; }
    void setPeaks(bool v) { if (v == m_peaks) return; m_peaks = v; update(); emit peaksChanged(); }
    qreal attackMs() const { return m_attackMs; }
    void setAttackMs(qreal v) { if (v == m_attackMs) return; m_attackMs = v; emit attackMsChanged(); }
    qreal releaseMs() const { return m_releaseMs; }
    void setReleaseMs(qreal v) { if (v == m_releaseMs) return; m_releaseMs = v; emit releaseMsChanged(); }

signals:
    void valuesChanged();
    void runningChanged();
    void barWidthChanged();
    void spacingChanged();
    void radiusChanged();
    void colorChanged();
    void colorTopChanged();
    void mirrorChanged();
    void peaksChanged();
    void attackMsChanged();
    void releaseMsChanged();

protected:
    void itemChange(ItemChange change, const ItemChangeData& value) override;

private:
    void advance();

    QList<qreal> m_values, m_disp, m_peak, m_peakV;
    bool m_running = false;
    qreal m_barWidth = 6, m_spacing = 3, m_radius = 3;
    QColor m_color = QColor("#ffb4a7"), m_colorTop = QColor("#ddc48c");
    bool m_mirror = false, m_peaks = true;
    qreal m_attackMs = 55, m_releaseMs = 190;

    QElapsedTimer m_clock;
    qint64 m_last = -1;
    QMetaObject::Connection m_frameConn;
};