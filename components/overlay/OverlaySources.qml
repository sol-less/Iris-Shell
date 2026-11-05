import Iris
import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire

Item {
    id: root

    // the live notification object that is currently on screen
    property var current: null

    function showVolume() {
        if (!Config.data.osd.volume) return
        const a = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null;
        if (a)
            Hud.showOsd("volume", a.volume, a.muted);

    }

    visible: false

    // ----- notifications -----
    NotificationServer {
        keepOnReload: true
        bodySupported: true
        imageSupported: true
        onNotification: (n) => {
            if (Config.data.notifications.dnd) return
            n.tracked = true;
            Hud.showNotification(n.appName, n.summary, n.body, n.appIcon, n.image, n.urgency === NotificationUrgency.Critical);
            root.current = n;
        }
    }

    Connections {
        function onLow(percent) {
            Hud.showNotification("Battery", "Low battery", percent + "% remaining", "battery-caution-symbolic", "", percent <= 10);
        }

        target: Battery
    }

    Connections {
        function onNotificationEnded(byUser) {
            if (!root.current)
                return ;

            if (byUser)
                root.current.dismiss();
            else
                root.current.expire();
            root.current = null;
        }

        target: Hud
    }

    // ----- volume -----
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        function onVolumeChanged() {
            root.showVolume();
        }

        function onMutedChanged() {
            root.showVolume();
        }

        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    }

    // ----- brightness -----
    Connections {
        function onLevelChanged() {
            if (Config.data.osd.brightness) Hud.showOsd("brightness", Brightness.level, false)
        }

        target: Brightness
    }

}
