import QtQuick
import Iris

Item {
    id: root
    property string text: ""
    property color color: Theme.onSurface
    property font font
    property bool running: true
    readonly property bool overflow: label.implicitWidth > width + 1

    implicitHeight: label.implicitHeight
    clip: true

    Text { id: label; x: 0; text: root.text; color: root.color; font: root.font }

    SequentialAnimation {
        running: root.overflow && root.running && root.visible
        loops: Animation.Infinite
        PauseAnimation { duration: 1400 }
        NumberAnimation {
            target: label; property: "x"
            to: -(label.implicitWidth - root.width) - 4
            duration: Math.max(900, (label.implicitWidth - root.width) * 28)
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: 900 }
        NumberAnimation { target: label; property: "x"; to: 0; duration: 500; easing.type: Easing.InOutSine }
    }
    onOverflowChanged: if (!overflow) label.x = 0
    onTextChanged: label.x = 0
}