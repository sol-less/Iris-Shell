#include "WavyBar.h"

#include <cmath>

#include <QPainter>
#include <QPainterPath>
#include <QQuickWindow>

namespace { constexpr qreal kPi = 3.14159265358979323846; }

void WavyBar::itemChange(ItemChange change, const ItemChangeData& value) {
    if (change == ItemSceneChange) {
        if (m_frameConn) QObject::disconnect(m_frameConn);
        if (value.window)
            m_frameConn = connect(value.window, &QQuickWindow::afterAnimating, this, &WavyBar::advance);
    }
    QQuickPaintedItem::itemChange(change, value);
}

void WavyBar::advance() {
    if (!m_running || !isVisible() || !(width() > 0)) { m_last = -1; return; }

    const qint64 now = m_clock.elapsed();
    if (m_last >= 0) {
        const qreal dt = qMin<qreal>(0.05, qreal(now - m_last) / 1000.0);
        const qreal period = qMax<qreal>(100.0, m_periodMs) / 1000.0;
        setPhase(std::fmod(m_phase + dt * 2.0 * kPi * m_speed / period, 2.0 * kPi));
    }
    m_last = now;
    update();                                   // schedules the next frame
}

void WavyBar::paint(QPainter* p) {
    const qreal w = width(), h = height();
    if (!(w > 0) || !(h > 0)) return;
    if (!std::isfinite(m_value) || !std::isfinite(m_amplitude) || !std::isfinite(m_wavelength)
        || !std::isfinite(m_phase) || !std::isfinite(m_thickness) || !std::isfinite(m_gap))
        return;                                 // a NaN here used to loop forever

    p->setRenderHint(QPainter::Antialiasing, true);

    const qreal cy = h / 2.0;
    const qreal pad = m_thickness / 2.0;
    const qreal handleW = 4.0;

    const qreal v = qBound<qreal>(0.0, m_value, 1.0);
    const qreal hx = pad + v * (w - 2.0 * pad);
    const qreal maxAmp = qMax<qreal>(0.0, cy - pad - 0.5);
    const qreal amp = qBound<qreal>(0.0, m_amplitude, maxAmp);

    const qreal waveEnd = hx - handleW / 2.0 - m_gap;
    const qreal trackStart = hx + handleW / 2.0 + m_gap;

    if (trackStart < w - pad) {                                      // inactive track
        p->setPen(QPen(m_trackColor, m_thickness, Qt::SolidLine, Qt::RoundCap));
        p->drawLine(QPointF(trackStart, cy), QPointF(w - pad, cy));
    }

    if (waveEnd > pad) {                                             // the wave
        const qreal k = 2.0 * kPi / qMax<qreal>(1.0, m_wavelength);
        const qreal ramp = qMax<qreal>(1.0, m_wavelength * 0.5);
        const qreal step = 1.5;

        QPainterPath path;
        qreal x = pad;
        for (int i = 0; i < 4000; ++i) {                             // bounded, whatever the input
            const qreal xx = qMin(x, waveEnd);
            const qreal env = qMin<qreal>(1.0, (xx - pad) / ramp);
            const qreal y = cy + amp * env * std::sin(k * (xx - pad) - m_phase);
            if (i == 0) path.moveTo(xx, y);
            else path.lineTo(xx, y);
            if (xx >= waveEnd) break;
            x += step;
        }

        p->setPen(QPen(m_color, m_thickness, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
        p->setBrush(Qt::NoBrush);
        p->drawPath(path);
    }

    p->setPen(Qt::NoPen);                                            // handle
    p->setBrush(m_handleColor);
    p->drawRoundedRect(QRectF(hx - handleW / 2.0, 0.0, handleW, h), handleW / 2.0, handleW / 2.0);
}