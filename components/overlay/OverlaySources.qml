import Quickshell.Services.Mpris
import QtQuick
import Iris
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire

Item {
    id: root
    visible: false

    property var live: ({})

    readonly property var player: {
        const ps = Mpris.players.values
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null
    }
    property string lastTrack: ""

    Timer {
        id: peekTimer
        interval: 450                                    // the cover usually arrives a moment after the title
        onTriggered: {
            const p = root.player
            if (!p || !p.isPlaying || !Config.data.notch.trackPeek) return
            Hud.showTrack(p.trackTitle, p.trackArtist, p.trackArtUrl ?? "", 3200)
        }
    }
    Connections {
        target: root.player
        function onTrackTitleChanged() {
            const t = root.player ? root.player.trackTitle : ""
            if (t === "" || t === root.lastTrack) return
            root.lastTrack = t
            peekTimer.restart()
        }
    }

    NotificationServer {
        keepOnReload: true
        bodySupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: (n) => {
            n.tracked = true                      // keeps it (and its image) alive while it is shown or queued

            const acts = []
            for (const a of n.actions) acts.push({ id: a.identifier, text: a.text })

            const urgency = n.urgency === NotificationUrgency.Critical ? 2
                          : (n.urgency === NotificationUrgency.Low ? 0 : 1)

            const id = Hud.notify(n.appName, n.summary, n.body, n.appIcon, n.image, urgency, acts)
            root.live[id] = n
        }
    }

    Connections {
        target: Hud
        function onNotificationEnded(id, byUser) {
            const n = root.live[id]
            delete root.live[id]
            if (!n) return
            if (byUser) n.dismiss()
            else n.expire()
        }
        function onActionRequested(id, actionId) {
            const n = root.live[id]
            if (!n) return
            for (const a of n.actions) {
                if (a.identifier === actionId) { a.invoke(); break }
            }
        }
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    function showVolume() {
        if (!Config.data.osd.volume) return
        const a = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        if (a) Hud.showOsd("volume", a.volume, a.muted)
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() { root.showVolume() }
        function onMutedChanged() { root.showVolume() }
    }

    Connections {
        target: Brightness
        function onLevelChanged() {
            if (Config.data.osd.brightness) Hud.showOsd("brightness", Brightness.level, false)
        }
    }

    Connections {
        target: Battery
        function onLow(percent) {
            Hud.notify("Battery", "Low battery", percent + "% remaining", "battery-caution-symbolic", "",
                       percent <= 10 ? 2 : 1, [])
        }
    }

    Connections {
        target: Countdown
        function onFinished(label) {
            Hud.notify("Timer", label !== "" ? label : "Timer finished", "Time is up", "alarm-symbolic", "", 2, [])
        }
    }

    IpcHandler {
        target: "audio"
        function micmute(): void {
            const s = Pipewire.defaultAudioSource
            if (!s || !s.audio) return
            s.audio.muted = !s.audio.muted
            Hud.showToast(s.audio.muted ? "Microphone muted" : "Microphone on")
        }
        function mute(): void {
            const s = Pipewire.defaultAudioSink
            if (s && s.audio) s.audio.muted = !s.audio.muted
        }
    }

    IpcHandler {
        target: "timer"
        function start(minutes: int): void { Countdown.start(minutes, "") }
        function startNamed(minutes: int, label: string): void { Countdown.start(minutes, label) }
        function pause(): void { Countdown.pause() }
        function resume(): void { Countdown.resume() }
        function cancel(): void { Countdown.cancel() }
    }

    IpcHandler {
        target: "notifications"
        function dnd(mode: string): void {                // on | off | toggle
            const want = mode === "on" ? true : (mode === "off" ? false : !Hud.dnd)
            if (want !== Hud.dnd) Hud.toggleDnd()
        }
        function clear(): void { Hud.clearHistory() }
        function skip(): void { Hud.skipCurrent() }
    }
}