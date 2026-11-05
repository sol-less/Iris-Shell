import QtQuick
import Iris

Item {
    id: root
    property real from: 0
    property real to: 1
    property real step: 0
    property real value: 0
    property string unit: ""
    signal moved(real v)

    implicitWidth: 330
    implicitHeight: 44

    readonly property real trackW: width - 80
    readonly property real ratio: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0
    readonly property real hx: ratio * trackW
    readonly property string label: (step > 0 && step < 1 ? value.toFixed(2) : Math.round(value)) + unit

    function setFromX(x) {
        const r = Math.max(0, Math.min(1, x / trackW))
        let v = from + r * (to - from)
        if (step > 0) v = Math.round(v / step) * step
        moved(Math.max(from, Math.min(to, v)))
    }

    Rectangle {                                           // active part
        y: (parent.height - height) / 2
        width: Math.max(0, root.hx - 8)
        height: 16
        topLeftRadius: 8; bottomLeftRadius: 8; topRightRadius: 3; bottomRightRadius: 3
        color: Theme.primary
    }

    Rectangle {                                           // inactive part
        x: root.hx + 8
        y: (parent.height - height) / 2
        width: Math.max(0, root.trackW - x)
        height: 16
        topLeftRadius: 3; bottomLeftRadius: 3; topRightRadius: 8; bottomRightRadius: 8
        color: Theme.secondaryContainer

        Rectangle {
            visible: parent.width > 22
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 4; height: 4; radius: 2
            color: Theme.onSecondaryContainer
        }
    }

    Rectangle {                                           // handle
        x: root.hx - width / 2
        width: mouse.pressed ? 3 : 5
        height: parent.height
        radius: width / 2
        color: Theme.primary
        Behavior on width { SpringAnimation { spring: 5; damping: 0.35 } }
    }

    Rectangle {                                           // value bubble while dragging
        width: bubbleText.implicitWidth + 22
        height: 28
        radius: 14
        x: root.hx - width / 2
        y: -36
        z: 10
        color: Theme.inverseSurface
        opacity: mouse.pressed ? 1 : 0
        scale: mouse.pressed ? 1 : 0.6
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.4 } }

        Text {
            id: bubbleText
            anchors.centerIn: parent
            text: root.label
            color: Theme.inverseOnSurface
            font.family: Config.data.appearance.font
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 66
        horizontalAlignment: Text.AlignRight
        text: root.label
        color: Theme.onSurface
        font.family: Config.data.appearance.font
        font.pixelSize: 13
        font.weight: Font.Medium
    }

    MouseArea {
        id: mouse
        width: root.trackW
        height: parent.height
        cursorShape: Qt.PointingHandCursor
        onPressed: (m) => root.setFromX(m.x)
        onPositionChanged: (m) => { if (pressed) root.setFromX(m.x) }
    }
}