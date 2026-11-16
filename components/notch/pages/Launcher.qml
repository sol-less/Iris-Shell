import QtQuick
import Quickshell
import Quickshell.Widgets
import M3Shapes
import Iris

Item {
    id: root

    signal launched(string appId)

    property int iconSize: 22
    property real maxStripWidth: 300
    property string hovered: ""
    property string pending: ""
    readonly property string fontFamily: Config.data.appearance.font

    function iconSrc(icon) {
        if (icon.startsWith("/")) return "file://" + icon
        return Quickshell.iconPath(icon, "application-x-executable")
    }

    implicitWidth: list.width + 10 + label.width
    implicitHeight: 36

    Timer { id: closeTimer; interval: 190; onTriggered: root.launched(root.pending) }     // lets the bounce play

    MouseArea {                                                // the wheel and the touchpad scroll the strip
        anchors.fill: list
        acceptedButtons: Qt.NoButton
        onWheel: (w) => {
            const d = w.angleDelta.x !== 0 ? w.angleDelta.x : w.angleDelta.y
            const lo = -list.leftMargin
            const hi = list.contentWidth + list.rightMargin - list.width
            list.contentX = Math.max(lo, Math.min(hi, list.contentX - d * 0.6))
        }
    }

    ListView {
        id: list
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(root.maxStripWidth, contentWidth + leftMargin + rightMargin)
        height: root.iconSize + 14
        orientation: ListView.Horizontal
        spacing: 6
        leftMargin: 4
        rightMargin: 4
        clip: true
        interactive: false
        model: Applications

        Behavior on contentX { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        delegate: Item {
            id: entry
            required property int index
            required property string name
            required property string icon
            required property string appId

            property real bounce: 0
            width: root.iconSize + 8
            height: list.height

            SequentialAnimation {
                id: pop
                NumberAnimation { target: entry; property: "bounce"; to: 1; duration: 110; easing.type: Easing.OutQuad }
                NumberAnimation { target: entry; property: "bounce"; to: 0; duration: 300; easing.type: Easing.OutBack }
            }

            MaterialShape {                                    // circle -> cookie on hover
                anchors.centerIn: parent
                implicitSize: root.iconSize + 10
                shape: mouse.containsMouse ? MaterialShape.Cookie6Sided : MaterialShape.Circle
                color: Theme.surfaceContainerHighest
                opacity: mouse.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: root.iconSize
                source: root.iconSrc(entry.icon)
                scale: (mouse.pressed ? 0.85 : (mouse.containsMouse ? 1.18 : 1)) * (1 + 0.45 * entry.bounce)
                Behavior on scale { Spring {} }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hovered = entry.name
                onExited: if (root.hovered === entry.name) root.hovered = ""
                onClicked: {
                    Applications.launchById(entry.appId)
                    pop.start()
                    root.pending = entry.appId
                    closeTimer.restart()
                }
            }
        }
    }

    Text {
        id: label
        anchors.left: list.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 110
        text: root.hovered !== "" ? root.hovered : "Apps"
        color: root.hovered !== "" ? Theme.onSurface : Theme.onSurfaceVariant
        font.family: root.fontFamily
        font.pixelSize: 12
        font.weight: Font.Medium
        elide: Text.ElideRight
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}