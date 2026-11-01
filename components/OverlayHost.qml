import Iris
import QtQuick
import "shell"

Item {
    id: root

    // 0 = hidden, 1 = fully shown
    property real progress: Hud.active ? 1 : 0

    implicitWidth: Hud.kind === "osd" ? osdView.implicitWidth : notifView.implicitWidth
    // placement inside the pill
    anchors.horizontalCenter: parent.horizontalCenter
    y: (1 - progress) * parent.height // slides up from below
    opacity: progress
    visible: progress > 0
    width: implicitWidth
    height: parent.height

    Osd {
        id: osdView

        anchors.fill: parent
        visible: Hud.kind === "osd"
        kind: Hud.osdKind
        level: Hud.osdLevel
        muted: Hud.osdMuted
    }

    Notification {
        id: notifView

        anchors.fill: parent
        visible: Hud.kind === "notification"
        app: Hud.app
        summary: Hud.summary
        body: Hud.body
        icon: Hud.icon
        image: Hud.image
    }

    // click a notification to dismiss it
    MouseArea {
        anchors.fill: parent
        enabled: Hud.kind === "notification" && Hud.active
        onClicked: Hud.hide()
    }

    Behavior on progress {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }

    }

}
