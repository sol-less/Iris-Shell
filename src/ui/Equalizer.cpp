#include "Equalizer.h"

#include <cmath>

#include <QLinearGradient>
#include <QPainter>
#include <QQuickWindow>

void Equalizer::itemChange(ItemChange change, const ItemChangeData& value) {
    if (change == ItemSceneChange) {
        if (m_frameConn) QObject::disconnect(m_frameConn);
        if (value.window)
            m_frameConn = connect(value.window, &QQuickWindow::afterAnimating, this, &Equalizer::advance);
    }
    QQuickPaintedItem::itemChange(change, value);
}

void Equalizer::advance() {
    if (!m_running || !isVisible() || !(width() > 0)) { m_last = -1; return; }

    const qint64 now = m_clock.elapsed();
    if (m_last < 0) { m_last = now; update(); return; }
    const qreal dt = qMin<qreal>(0.05, qreal(now - m_last) / 1000.0);
    m_last = now;

    const int n = m_values.size();
    if (m_disp.size() != n) {
        m_disp = QList<qreal>(n, 0.0);
        m_peak = QList<qreal>(n, 0.0);
        m_peakV = QList<qreal>(n, 0.0);
    }

    const qreal ka = 1.0 - std::exp(-dt / (qMax<qreal>(1.0, m_attackMs) / 1000.0));
    const qreal kr = 1.0 - std::exp(-dt / (qMax<qreal>(1.0, m_releaseMs) / 1000.0));

    bool awake = false;
    for (int i = 0; i < n; ++i) {
        const qreal target = std::isfinite(m_values[i]) ? qBound<qreal>(0.0, m_values[i], 1.0) : 0.0;
        m_disp[i] += (target - m_disp[i]) * (target > m_disp[i] ? ka : kr);

        if (m_disp[i] >= m_peak[i]) { m_peak[i] = m_disp[i]; m_peakV[i] = 0.0; }
        else {
            m_peakV[i] += 2.4 * dt;                                    // gravity
            m_peak[i] = qMax(m_disp[i], m_peak[i] - m_peakV[i] * dt);
        }
        if (target > 0.004 || m_disp[i] > 0.004 || m_peak[i] > 0.004) awake = true;
    }
    if (awake) update();                                               // silence: no more frames are drawn
}

void Equalizer::paint(QPainter* p) {
    const qreal w = width(), h = height();
    if (!(w > 0) || !(h > 0) || m_disp.isEmpty()) return;

    p->setRenderHint(QPainter::Antialiasing, true);
    p->setPen(Qt::NoPen);

    const qreal step = m_barWidth + m_spacing;
    const qreal minH = qMin(h, m_barWidth);                            // a silent bar is a dot
    const qreal r = qMin(m_radius, m_barWidth / 2.0);

    QLinearGradient g;
    if (m_mirror) { g = QLinearGradient(0, h / 2.0, 0, 0); g.setSpread(QGradient::ReflectSpread); }
    else g = QLinearGradient(0, h, 0, 0);
    g.setColorAt(0.0, m_color);
    g.setColorAt(1.0, m_colorTop);
    const QBrush brush(g);

    for (int i = 0; i < m_disp.size(); ++i) {
        const qreal x = i * step;
        if (x + m_barWidth > w + 0.5) break;

        const qreal bh = qMax(minH, qBound<qreal>(0.0, m_disp[i], 1.0) * h);
        const qreal y = m_mirror ? (h - bh) / 2.0 : h - bh;
        p->setBrush(brush);
        p->drawRoundedRect(QRectF(x, y, m_barWidth, bh), r, r);

        if (m_peaks && !m_mirror) {
            const qreal py = qMax(0.0, h - qMax(minH, m_peak[i] * h) - 4.0);
            if (m_peak[i] * h > bh + 2.0) {
                p->setBrush(m_colorTop);
                p->drawRoundedRect(QRectF(x, py, m_barWidth, 2.5), 1.2, 1.2);
            }
        }
    }
}