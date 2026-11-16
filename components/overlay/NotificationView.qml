import QtQuick
import Iris

Item {
    id: root

    readonly property real swap: Hud.noteSwap

    implicitWidth: prevLayer.implicitWidth * (1 - swap) + curLayer.implicitWidth * swap
    implicitHeight: prevLayer.implicitHeight * (1 - swap) + curLayer.implicitHeight * swap

    MouseArea { anchors.fill: parent; onClicked: Hud.hide() }          // click anywhere: dismiss

    NotificationContent {
        id: prevLayer
        visible: root.swap < 0.999
        y: (root.height - implicitHeight) / 2 - root.swap * 10
        opacity: 1 - root.swap
        app: Hud.prevApp
        summary: Hud.prevSummary
        body: Hud.prevBody
        icon: Hud.prevIcon
        image: Hud.prevImage
        urgency: Hud.prevUrgency
        actions: Hud.prevActions
    }

    NotificationContent {
        id: curLayer
        y: (root.height - implicitHeight) / 2 + (1 - root.swap) * 14
        opacity: root.swap
        interactive: true
        app: Hud.app
        summary: Hud.summary
        body: Hud.body
        icon: Hud.icon
        image: Hud.image
        urgency: Hud.urgency
        actions: Hud.actions
    }

    Rectangle {                                          // how many are waiting
        visible: Hud.queued > 0
        anchors.right: parent.right
        anchors.rightMargin: 14
        y: 10
        implicitWidth: queuedText.implicitWidth + 16
        implicitHeight: 20
        radius: 10
        color: Theme.secondaryContainer

        Text {
            id: queuedText
            anchors.centerIn: parent
            text: "+" + Hud.queued
            color: Theme.onSecondaryContainer
            font.family: Config.data.appearance.font
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }

    Rectangle {                                          // the time left; it freezes while hovering
        x: 24
        y: root.height - 7
        width: Math.max(0, (root.width - 48) * Hud.noteProgress)
        height: 3
        radius: 1.5
        color: Hud.urgency >= 2 ? Theme.error : Theme.primary
        opacity: 0.8
    }

    HoverHandler {
        enabled: Config.data.notifications.pauseOnHover
        onHoveredChanged: Hud.pauseNotifications(hovered)
    }
}