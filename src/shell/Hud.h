#pragma once

#include <QElapsedTimer>
#include <QList>
#include <QObject>
#include <QString>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class Hud : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(QString kind READ kind NOTIFY
                 kindChanged) // "osd" | "notification" | "toast"
  Q_PROPERTY(bool active READ active NOTIFY activeChanged)

  Q_PROPERTY(QString osdKind READ osdKind NOTIFY osdChanged)
  Q_PROPERTY(qreal osdLevel READ osdLevel NOTIFY osdChanged)
  Q_PROPERTY(bool osdMuted READ osdMuted NOTIFY osdChanged)
  Q_PROPERTY(qreal osdShown READ osdShown NOTIFY animChanged)
  Q_PROPERTY(qreal osdMute READ osdMute NOTIFY animChanged)
  Q_PROPERTY(qreal osdOver READ osdOver NOTIFY animChanged)
  Q_PROPERTY(qreal osdBoost READ osdBoost NOTIFY animChanged)
  Q_PROPERTY(qreal osdPhase READ osdPhase NOTIFY animChanged)
  Q_PROPERTY(
      qreal squiggle READ squiggle WRITE setSquiggle NOTIFY squiggleChanged)
  Q_PROPERTY(int osdMs MEMBER m_osdMs)

  Q_PROPERTY(int noteId READ noteId NOTIFY noteChanged)
  Q_PROPERTY(QString app READ app NOTIFY noteChanged)
  Q_PROPERTY(QString summary READ summary NOTIFY noteChanged)
  Q_PROPERTY(QString body READ body NOTIFY noteChanged)
  Q_PROPERTY(QString icon READ icon NOTIFY noteChanged)
  Q_PROPERTY(QString image READ image NOTIFY noteChanged)
  Q_PROPERTY(int urgency READ urgency NOTIFY noteChanged)
  Q_PROPERTY(QVariantList actions READ actions NOTIFY noteChanged)
  Q_PROPERTY(QString prevApp READ prevApp NOTIFY noteChanged)
  Q_PROPERTY(QString prevSummary READ prevSummary NOTIFY noteChanged)
  Q_PROPERTY(QString prevBody READ prevBody NOTIFY noteChanged)
  Q_PROPERTY(QString prevIcon READ prevIcon NOTIFY noteChanged)
  Q_PROPERTY(QString prevImage READ prevImage NOTIFY noteChanged)
  Q_PROPERTY(int prevUrgency READ prevUrgency NOTIFY noteChanged)
  Q_PROPERTY(QVariantList prevActions READ prevActions NOTIFY noteChanged)
  Q_PROPERTY(qreal noteSwap READ noteSwap NOTIFY
                 animChanged) // 0 -> 1 while the content slides
  Q_PROPERTY(qreal noteProgress READ noteProgress NOTIFY
                 animChanged) // 1 -> 0, the time left
  Q_PROPERTY(int queued READ queued NOTIFY queuedChanged)
  Q_PROPERTY(int notificationMs MEMBER m_notificationMs)
  Q_PROPERTY(int criticalMs MEMBER m_criticalMs)
  Q_PROPERTY(int maxQueue MEMBER m_maxQueue)
  Q_PROPERTY(int historyMax MEMBER m_historyMax)

  Q_PROPERTY(
      bool dnd READ dnd WRITE setDnd NOTIFY dndChanged) // the manual switch
  Q_PROPERTY(bool dndActive READ dndActive NOTIFY
                 dndActiveChanged) // manual or quiet hours
  Q_PROPERTY(
      bool dndAllowCritical MEMBER m_allowCritical NOTIFY dndActiveChanged)
  Q_PROPERTY(bool quietEnabled MEMBER m_quietEnabled NOTIFY dndActiveChanged)
  Q_PROPERTY(QString quietFrom MEMBER m_quietFrom NOTIFY dndActiveChanged)
  Q_PROPERTY(QString quietTo MEMBER m_quietTo NOTIFY dndActiveChanged)
  Q_PROPERTY(int missed READ missed NOTIFY missedChanged)
  Q_PROPERTY(
      bool caffeine READ caffeine WRITE setCaffeine NOTIFY caffeineChanged)

  Q_PROPERTY(QVariantList history READ history NOTIFY historyChanged)
  Q_PROPERTY(QString toast READ toast NOTIFY toastChanged)
  Q_PROPERTY(int unread READ unread NOTIFY unreadChanged)
  Q_PROPERTY(QString trackTitle READ trackTitle NOTIFY trackChanged)
  Q_PROPERTY(QString trackArtist READ trackArtist NOTIFY trackChanged)
  Q_PROPERTY(QString trackArt READ trackArt NOTIFY trackChanged)

public:
  struct Note {
    int id = 0;
    QString app, summary, body, icon, image;
    int urgency = 1;      // 0 low, 1 normal, 2 critical
    QVariantList actions; // [{ id, text }]
    qint64 time = 0;      // ms since epoch
    bool silenced = false;
  };

  int unread() const { return m_unread; }
  QString trackTitle() const { return m_trackTitle; }
  QString trackArtist() const { return m_trackArtist; }
  QString trackArt() const { return m_trackArt; }
  Q_INVOKABLE void showTrack(const QString &title, const QString &artist,
                             const QString &art, int ms = 3200);
  Q_INVOKABLE void markRead();

  explicit Hud(QObject *parent = nullptr);

  QString kind() const { return m_kind; }
  bool active() const { return m_active; }

  QString osdKind() const { return m_osdKind; }
  qreal osdLevel() const { return m_osdLevel; }
  bool osdMuted() const { return m_osdMuted; }
  qreal osdShown() const { return m_shown; }
  qreal osdMute() const { return m_mute; }
  qreal osdOver() const { return m_over; }
  qreal osdBoost() const { return m_boost; }
  qreal osdPhase() const { return m_phase; }
  qreal squiggle() const { return m_squiggle; }
  void setSquiggle(qreal s);

  int noteId() const { return m_cur.id; }
  QString app() const { return m_cur.app; }
  QString summary() const { return m_cur.summary; }
  QString body() const { return m_cur.body; }
  QString icon() const { return m_cur.icon; }
  QString image() const { return m_cur.image; }
  int urgency() const { return m_cur.urgency; }
  QVariantList actions() const { return m_cur.actions; }
  QString prevApp() const { return m_prev.app; }
  QString prevSummary() const { return m_prev.summary; }
  QString prevBody() const { return m_prev.body; }
  QString prevIcon() const { return m_prev.icon; }
  QString prevImage() const { return m_prev.image; }
  int prevUrgency() const { return m_prev.urgency; }
  QVariantList prevActions() const { return m_prev.actions; }
  qreal noteSwap() const { return m_swap; }
  qreal noteProgress() const;
  int queued() const { return m_queue.size(); }

  bool dnd() const { return m_dnd; }
  void setDnd(bool on);
  bool dndActive() const;
  int missed() const { return m_missed; }
  bool caffeine() const { return m_caffeine; }
  void setCaffeine(bool on);

  QVariantList history() const;
  QString toast() const { return m_toast; }

  Q_INVOKABLE void showOsd(const QString &kind, qreal level, bool muted);
  Q_INVOKABLE void showToast(const QString &text, int ms = 1500);
  Q_INVOKABLE int notify(const QString &app, const QString &summary,
                         const QString &body, const QString &icon,
                         const QString &image, int urgency,
                         const QVariantList &actions);
  Q_INVOKABLE void hide(); // the user dismissed what is showing
  Q_INVOKABLE void skipCurrent();
  Q_INVOKABLE void invokeAction(int id, const QString &actionId);
  Q_INVOKABLE void pauseNotifications(bool paused) { m_paused = paused; }
  Q_INVOKABLE void toggleDnd();
  Q_INVOKABLE void clearMissed();
  Q_INVOKABLE void clearHistory();
  Q_INVOKABLE void removeHistory(int id);

signals:
  void kindChanged();
  void activeChanged();
  void osdChanged();
  void animChanged();
  void squiggleChanged();
  void noteChanged();
  void queuedChanged();
  void dndChanged();
  void dndActiveChanged();
  void missedChanged();
  void caffeineChanged();
  void historyChanged();
  void toastChanged();
  void notificationEnded(int id, bool byUser);
  void actionRequested(int id, const QString &actionId);
  void unreadChanged();
  void trackChanged();

private:
  void open(const QString &kind, int ms);
  void close();
  void finishTransient();
  void suspendNote();
  void startNote(const Note &n, bool inPlace);
  void advance(bool byUser);
  void addHistory(const Note &n);
  void ensureTick();
  void tick();
  bool inQuietHours() const;

  QString m_kind = QStringLiteral("osd");
  bool m_active = false;
  bool m_armed = false;
  bool m_paused = false;

  QString m_osdKind = QStringLiteral("volume");
  qreal m_osdLevel = 0;
  bool m_osdMuted = false;
  qreal m_squiggle = 0.6;
  int m_osdMs = 1600;
  qreal m_shown = 0, m_mute = 0, m_over = 0, m_boost = 0, m_phase = 0;

  Note m_cur, m_prev;
  bool m_hasCur = false;
  QList<Note> m_queue;
  QList<Note> m_history;
  qreal m_swap = 1.0;
  int m_notificationMs = 4500;
  int m_criticalMs = 8000;
  int m_maxQueue = 8;
  int m_historyMax = 50;
  int m_nextId = 1;

  bool m_dnd = false;
  bool m_allowCritical = true;
  bool m_quietEnabled = false;
  QString m_quietFrom = QStringLiteral("22:00");
  QString m_quietTo = QStringLiteral("07:00");
  int m_missed = 0;
  bool m_lastDndActive = false;
  bool m_caffeine = false;
  QString m_toast;

  qreal m_remain = 0, m_total = 1;
  qreal m_idle = 0;
  QTimer m_tick;
  QTimer m_dndCheck;
  QElapsedTimer m_animClock;
  int m_unread = 0;
  QString m_trackTitle, m_trackArtist, m_trackArt;
};