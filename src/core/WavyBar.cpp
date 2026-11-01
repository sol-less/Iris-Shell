#include "WavyBar.h"

#include <cmath>

#include <QPainter>
#include <QPainterPath>

void WavyBar::paint(QPainter* p) {
    p->setRenderHint(QPainter::Antialiasing, true);

    const qreal w = width();
    const qreal h = height();
    if (w <= 0 || h <= 0) return;

    const qreal pi = 3.14159265358979323846;
    const qreal cy = h / 2.0;
    const qreal pad = m_thickness / 2.0;
    const qreal handleW = 4.0;

    const qreal v = qBound<qreal>(0.0, m_value, 1.0);
    const qreal hx = pad + v * (w - 2.0 * pad);                       // handle centre
    const qreal maxAmp = qMax<qreal>(0.0, cy - pad - 0.5);            // never draw outside the item
    const qreal amp = qBound<qreal>(0.0, m_amplitude, maxAmp);

    const qreal waveEnd = hx - handleW / 2.0 - m_gap;
    const qreal trackStart = hx + handleW / 2.0 + m_gap;

    // ----- inactive track: straight line after the handle -----
    if (trackStart < w - pad) {
        p->setPen(QPen(m_trackColor, m_thickness, Qt::SolidLine, Qt::RoundCap));
        p->drawLine(QPointF(trackStart, cy), QPointF(w - pad, cy));
    }

    // ----- active track: the wave -----
    if (waveEnd > pad) {
        const qreal k = 2.0 * pi / qMax<qreal>(1.0, m_wavelength);
        const qreal ramp = qMax<qreal>(1.0, m_wavelength * 0.5);      // wave eases in from the start
        const qreal step = 1.5;

        QPainterPath path;
        for (qreal x = pad;; x += step) {
            const qreal xx = qMin(x, waveEnd);
            const qreal env = qMin<qreal>(1.0, (xx - pad) / ramp);
            const qreal y = cy + amp * env * std::sin(k * (xx - pad) - m_phase);
            if (x == pad) path.moveTo(xx, y);
            else path.lineTo(xx, y);
            if (xx >= waveEnd) break;
        }

        p->setPen(QPen(m_color, m_thickness, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
        p->setBrush(Qt::NoBrush);
        p->drawPath(path);
    }

    // ----- handle -----
    p->setPen(Qt::NoPen);
    p->setBrush(m_handleColor);
    p->drawRoundedRect(QRectF(hx - handleW / 2.0, 0.0, handleW, h), handleW / 2.0, handleW / 2.0);
}