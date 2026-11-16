import Iris
import QtQuick

Item {
    id: root

    property real progress: Hud.active ? 1 : 0
    readonly property Item view: Hud.kind === "osd" ? osdView : Hud.kind === "toast" ? toastView : Hud.kind === "track" ? trackView : notifView

    implicitWidth: view.implicitWidth
    implicitHeight: view.implicitHeight
    anchors.horizontalCenter: parent.horizontalCenter
    y: (1 - progress) * parent.height
    opacity: Math.max(0, Math.min(1, progress))
    visible: progress > 0.001
    width: implicitWidth
    height: parent.height

    OsdView {
        id: osdView

        anchors.fill: parent
        visible: Hud.kind === "osd"
        kind: Hud.osdKind
        level: Hud.osdLevel
        muted: Hud.osdMuted
    }

    NotificationView {
        id: notifView

        anchors.fill: parent
        visible: Hud.kind === "notification"
    }

    ToastView {
        id: toastView

        anchors.fill: parent
        visible: Hud.kind === "toast"
        text: Hud.toast
    }

    TrackView {
        id: trackView

        anchors.fill: parent
        visible: Hud.kind === "track"
    }

    Behavior on progress {
        Spring {
        }

    }

}
