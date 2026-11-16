#include "Hud.h"

#include <cmath>

#include <QDateTime>
#include <QTime>

namespace {

constexpr qreal kPi = 3.14159265358979323846;

int minutesOf(const QString &s, int fallback) {
  const QTime t = QTime::fromString(s.trimmed(), QStringLiteral("H:mm"));
  return t.isValid() ? t.hour() * 60 + t.minute() : fallback;
}

QVariantMap toMap(const Hud::Note &n) {
  return {{"id", n.id},           {"app", n.app},
          {"summary", n.summary}, {"body", n.body},
          {"icon", n.icon},       {"image", n.image},
          {"urgency", n.urgency}, {"actions", n.actions},
          {"time", n.time},       {"silenced", n.silenced}};
}

} // namespace

Hud::Hud(QObject *parent) : QObject(parent) {
  m_tick.setInterval(16);
  connect(&m_tick, &QTimer::timeout, this, &Hud::tick);

  m_dndCheck.setInterval(30000);
  connect(&m_dndCheck, &QTimer::timeout, this, [this] {
    const bool now = dndActive();
    if (now != m_lastDndActive) {
      m_lastDndActive = now;
      emit dndActiveChanged();
    }
  });
  m_dndCheck.start();

  QTimer::singleShot(2500, this, [this] { m_armed = true; });
}


void Hud::open(const QString &kind, int ms) {
  if (kind != m_kind) {
    m_kind = kind;
    emit kindChanged();
  }
  if (!m_active) {
    m_active = true;
    emit activeChanged();
  }
  m_remain = ms;
  m_total = qMax(1, ms);
  ensureTick();
}

void Hud::close() {
  m_paused = false;
  if (m_active) {
    m_active = false;
    emit activeChanged();
  }
}

void Hud::finishTransient() {
  close();
  if (!m_queue.isEmpty())
    startNote(m_queue.takeFirst(), false);
}

void Hud::suspendNote() {
  if (m_active && m_kind == QLatin1String("notification") && m_hasCur) {
    m_queue.prepend(m_cur);
    m_hasCur = false;
    emit queuedChanged();
  }
}

void Hud::ensureTick() {
  if (!m_tick.isActive()) {
    m_animClock.start();
    m_tick.start();
  }
  m_idle = 0;
}

void Hud::tick() {
  const qreal dt = qBound<qreal>(0.0, m_animClock.restart() / 1000.0, 0.05);
  auto approach = [dt](qreal v, qreal target, qreal tau) {
    return v + (target - v) * (1.0 - std::exp(-dt / tau));
  };

  m_shown = approach(m_shown, qMin<qreal>(1.0, m_osdLevel), 0.07);
  m_mute = approach(m_mute, m_osdMuted ? 1.0 : 0.0, 0.10);
  m_over = approach(m_over, m_osdLevel > 1.0 ? 1.0 : 0.0, 0.12);
  m_boost *= std::exp(-dt / 0.35);
  const qreal period =
      1.5 / (1.0 + 1.2 * m_boost); // the wave speeds up on a change
  m_phase = std::fmod(m_phase + dt * 2.0 * kPi / period, 2.0 * kPi);

  if (m_swap < 1.0) {
    m_swap = approach(m_swap, 1.0, 0.085);
    if (m_swap > 0.998)
      m_swap = 1.0;
  }

  if (m_active) {
    m_idle = 0;
    const bool isNote = m_kind == QLatin1String("notification");
    if (!(isNote && m_paused))
      m_remain -= dt * 1000.0;
    if (m_remain <= 0) {
      if (isNote)
        advance(false);
      else
        finishTransient();
    }
  } else {
    m_idle += dt;
    if (m_idle > 0.9)
      m_tick.stop(); // nothing runs while the pill is idle
  }

  emit animChanged();
}

qreal Hud::noteProgress() const {
  if (!m_active || m_kind != QLatin1String("notification") || m_total <= 0)
    return 0.0;
  return qBound<qreal>(0.0, m_remain / m_total, 1.0);
}


void Hud::setSquiggle(qreal s) {
  s = qBound<qreal>(0.0, s, 1.0);
  if (s == m_squiggle)
    return;
  m_squiggle = s;
  emit squiggleChanged();
}

void Hud::showOsd(const QString &kind, qreal level, bool muted) {
  if (!m_armed || !std::isfinite(level))
    return; // NaN from a half-ready audio node
  suspendNote();

  const bool wasHidden = !m_active || m_kind != QLatin1String("osd");
  m_osdKind = kind;
  m_osdLevel = qMax<qreal>(0.0, level);
  m_osdMuted = muted;
  emit osdChanged();

  if (wasHidden) { // appear at the right value
    m_shown = qMin<qreal>(1.0, m_osdLevel);
    m_mute = muted ? 1.0 : 0.0;
    m_over = m_osdLevel > 1.0 ? 1.0 : 0.0;
  }
  m_boost = 1.0;
  open(QStringLiteral("osd"), m_osdMs);
}

void Hud::showToast(const QString &text, int ms) {
  if (text.isEmpty())
    return;
  suspendNote();
  m_toast = text;
  emit toastChanged();
  open(QStringLiteral("toast"), ms);
}


int Hud::notify(const QString &app, const QString &summary, const QString &body,
                const QString &icon, const QString &image, int urgency,
                const QVariantList &actions) {
  Note n;
  n.id = m_nextId++;
  n.app = app;
  n.summary = summary;
  n.body = body;
  n.icon = icon;
  n.image = image;
  n.urgency = qBound(0, urgency, 2);
  n.actions = actions;
  n.time = QDateTime::currentMSecsSinceEpoch();
  n.silenced = dndActive() && !(n.urgency >= 2 && m_allowCritical);

  addHistory(n);

  ++m_unread;
  emit unreadChanged();

  if (n.silenced) {
    ++m_missed;
    emit missedChanged();
    const int id = n.id; // queued: the caller has not stored its object yet
    QMetaObject::invokeMethod(
        this, [this, id] { emit notificationEnded(id, false); },
        Qt::QueuedConnection);
    return id;
  }

  const bool showing =
      m_active && m_kind == QLatin1String("notification") && m_hasCur;
  if (!showing) { // idle, or an OSD or toast is up
    startNote(n, false);
    return n.id;
  }

  int pos = m_queue.size();
  if (n.urgency >= 2) {
    pos = 0;
    while (pos < m_queue.size() && m_queue.at(pos).urgency >= 2)
      ++pos;
  }
  m_queue.insert(pos, n);

  while (m_queue.size() >
         m_maxQueue) { // the queue is full: the last one is dropped
    const Note dropped = m_queue.takeLast();
    const int id = dropped.id;
    QMetaObject::invokeMethod(
        this, [this, id] { emit notificationEnded(id, false); },
        Qt::QueuedConnection);
  }
  emit queuedChanged();

  if (n.urgency >= 2 && m_cur.urgency < 2)
    advance(false); // a critical one cuts the current one short
  return n.id;
}

void Hud::startNote(const Note &n, bool inPlace) {
  if (inPlace && m_hasCur) {
    m_prev = m_cur;
    m_swap = 0.0;
  } // slide from the old content to the new
  else {
    m_prev = Note();
    m_swap = 1.0;
  }

  m_cur = n;
  m_hasCur = true;
  emit noteChanged();
  emit queuedChanged();
  open(QStringLiteral("notification"),
       n.urgency >= 2 ? m_criticalMs : m_notificationMs);
}

void Hud::advance(bool byUser) {
  if (m_hasCur)
    emit notificationEnded(m_cur.id, byUser);

  if (!m_queue.isEmpty()) {
    startNote(m_queue.takeFirst(),
              true); // in place: the pill morphs, it does not close
    return;
  }
  m_hasCur = false;
  emit queuedChanged();
  close();
}

void Hud::hide() {
  if (m_active && m_kind == QLatin1String("notification"))
    advance(true);
  else if (m_active)
    finishTransient();
}

void Hud::skipCurrent() {
  if (m_active && m_kind == QLatin1String("notification"))
    advance(false);
}

void Hud::invokeAction(int id, const QString &actionId) {
  emit actionRequested(id, actionId);
  if (m_active && m_hasCur && m_cur.id == id)
    advance(true);
}


void Hud::addHistory(const Note &n) {
  m_history.prepend(n);
  while (m_history.size() > m_historyMax)
    m_history.removeLast();
  emit historyChanged();
}

QVariantList Hud::history() const {
  QVariantList out;
  out.reserve(m_history.size());
  for (const Note &n : m_history)
    out.append(toMap(n));
  return out;
}

void Hud::clearHistory() {
  if (m_history.isEmpty())
    return;
  m_history.clear();
  emit historyChanged();
}

void Hud::removeHistory(int id) {
  for (int i = 0; i < m_history.size(); ++i) {
    if (m_history.at(i).id != id)
      continue;
    m_history.removeAt(i);
    emit historyChanged();
    return;
  }
}


bool Hud::inQuietHours() const {
  const int from = minutesOf(m_quietFrom, 22 * 60);
  const int to = minutesOf(m_quietTo, 7 * 60);
  if (from == to)
    return false;
  const QTime t = QTime::currentTime();
  const int m = t.hour() * 60 + t.minute();
  return from < to ? (m >= from && m < to)
                   : (m >= from || m < to); // also across midnight
}

bool Hud::dndActive() const {
  return m_dnd || (m_quietEnabled && inQuietHours());
}

void Hud::setDnd(bool on) {
  if (on == m_dnd)
    return;
  m_dnd = on;
  m_lastDndActive = dndActive();
  emit dndChanged();
  emit dndActiveChanged();
}

void Hud::toggleDnd() {
  const bool on = !m_dnd;
  setDnd(on);
  if (on) {
    showToast(QStringLiteral("Do not disturb on"));
  } else {
    showToast(
        m_missed > 0
            ? QStringLiteral("Do not disturb off · %1 missed").arg(m_missed)
            : QStringLiteral("Do not disturb off"));
    clearMissed();
  }
}

void Hud::clearMissed() {
  if (m_missed == 0)
    return;
  m_missed = 0;
  emit missedChanged();
}

void Hud::setCaffeine(bool on) {
  if (on == m_caffeine)
    return;
  m_caffeine = on;
  emit caffeineChanged();
}

void Hud::showTrack(const QString &title, const QString &artist,
                    const QString &art, int ms) {
  if (title.isEmpty())
    return;
  suspendNote(); // a notification waits, then comes back
  m_trackTitle = title;
  m_trackArtist = artist;
  m_trackArt = art;
  emit trackChanged();
  open(QStringLiteral("track"), ms);
}

void Hud::markRead() {
  if (m_unread == 0)
    return;
  m_unread = 0;
  emit unreadChanged();
}