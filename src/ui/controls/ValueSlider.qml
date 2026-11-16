import QtQuick
import M3Shapes
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
    implicitHeight: 48

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

    Rectangle {
        y: (parent.height - height) / 2
        width: Math.max(0, root.hx - 18)
        height: 20
        topLeftRadius: 10; bottomLeftRadius: 10; topRightRadius: 4; bottomRightRadius: 4
        color: Theme.primary
    }

    Rectangle {
        x: root.hx + 18
        y: (parent.height - height) / 2
        width: Math.max(0, root.trackW - x)
        height: 20
        topLeftRadius: 4; bottomLeftRadius: 4; topRightRadius: 10; bottomRightRadius: 10
        color: Theme.secondaryContainer
    }

    MaterialShape {
        x: root.hx - width / 2
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: mouse.pressed ? 36 : 28
        shape: MaterialShape.Cookie4Sided
        color: Theme.primary
        rotation: root.ratio * 120
        Behavior on implicitSize { Spring {} }
    }

    Rectangle {
        width: bubbleText.implicitWidth + 24
        height: 30
        radius: 15
        x: root.hx - width / 2
        y: -38
        z: 10
        color: Theme.inverseSurface
        opacity: mouse.pressed ? 1 : 0
        scale: mouse.pressed ? 1 : 0.6
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on scale { Spring {} }

        Text {
            id: bubbleText
            anchors.centerIn: parent
            text: root.label
            color: Theme.inverseOnSurface
            font.family: Config.data.appearance.font
            font.pixelSize: 13
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
        font.pixelSize: 14
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