import QtQuick
import M3Shapes
import Iris

Item {
    id: root
    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 64
    implicitHeight: 36

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Theme.outline
        Behavior on color { ColorAnimation { duration: 180 } }

        MaterialShape {
            id: thumb
            readonly property real goal: mouse.pressed ? 30 : (root.checked ? 26 : 18)
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? track.width - 5 - goal : 9 - (goal - 18) / 2
            implicitSize: goal
            shape: root.checked ? MaterialShape.Cookie6Sided : MaterialShape.Circle
            color: root.checked ? Theme.onPrimary : Theme.outline
            rotation: root.checked ? 180 : 0
            Behavior on x { Spring {} }
            Behavior on implicitSize { Spring {} }
            Behavior on rotation { Spring {} }
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}