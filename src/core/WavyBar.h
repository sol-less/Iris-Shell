#pragma once

#include <QColor>
#include <QQuickPaintedItem>
#include <QtQml/qqmlregistration.h>

class WavyBar : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(qreal value READ value WRITE setValue NOTIFY valueChanged)                  // 0 to 1
    Q_PROPERTY(qreal amplitude READ amplitude WRITE setAmplitude NOTIFY amplitudeChanged)  // wave height in px
    Q_PROPERTY(qreal wavelength READ wavelength WRITE setWavelength NOTIFY wavelengthChanged) // px per wave
    Q_PROPERTY(qreal phase READ phase WRITE setPhase NOTIFY phaseChanged)                  // radians, animate this
    Q_PROPERTY(qreal thickness READ thickness WRITE setThickness NOTIFY thicknessChanged)  // line width in px
    Q_PROPERTY(qreal gap READ gap WRITE setGap NOTIFY gapChanged)                          // space around the handle
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)                 // active wave
    Q_PROPERTY(QColor trackColor READ trackColor WRITE setTrackColor NOTIFY trackColorChanged)
    Q_PROPERTY(QColor handleColor READ handleColor WRITE setHandleColor NOTIFY handleColorChanged)

public:
    explicit WavyBar(QQuickItem* parent = nullptr) : QQuickPaintedItem(parent) {}

    void paint(QPainter* painter) override;

    qreal value() const { return m_value; }
    void setValue(qreal v) { if (assign(m_value, v)) emit valueChanged(); }

    qreal amplitude() const { return m_amplitude; }
    void setAmplitude(qreal v) { if (assign(m_amplitude, v)) emit amplitudeChanged(); }

    qreal wavelength() const { return m_wavelength; }
    void setWavelength(qreal v) { if (assign(m_wavelength, v)) emit wavelengthChanged(); }

    qreal phase() const { return m_phase; }
    void setPhase(qreal v) { if (assign(m_phase, v)) emit phaseChanged(); }

    qreal thickness() const { return m_thickness; }
    void setThickness(qreal v) { if (assign(m_thickness, v)) emit thicknessChanged(); }

    qreal gap() const { return m_gap; }
    void setGap(qreal v) { if (assign(m_gap, v)) emit gapChanged(); }

    QColor color() const { return m_color; }
    void setColor(const QColor& v) { if (assign(m_color, v)) emit colorChanged(); }

    QColor trackColor() const { return m_trackColor; }
    void setTrackColor(const QColor& v) { if (assign(m_trackColor, v)) emit trackColorChanged(); }

    QColor handleColor() const { return m_handleColor; }
    void setHandleColor(const QColor& v) { if (assign(m_handleColor, v)) emit handleColorChanged(); }

signals:
    void valueChanged();
    void amplitudeChanged();
    void wavelengthChanged();
    void phaseChanged();
    void thicknessChanged();
    void gapChanged();
    void colorChanged();
    void trackColorChanged();
    void handleColorChanged();

private:
    template <typename T>
    bool assign(T& member, const T& v) {
        if (member == v) return false;
        member = v;
        update();   // repaint
        return true;
    }

    qreal m_value = 0.5;
    qreal m_amplitude = 3.0;
    qreal m_wavelength = 30.0;
    qreal m_phase = 0.0;
    qreal m_thickness = 4.0;
    qreal m_gap = 3.0;
    QColor m_color = QColor("#ffb4a7");
    QColor m_trackColor = QColor("#534340");
    QColor m_handleColor = QColor("#ffb4a7");
};