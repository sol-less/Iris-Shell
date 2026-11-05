import QtQuick
import QtQuick.Shapes
import Iris

Item {
    id: root
    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 52
    implicitHeight: 32

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Theme.outline
        Behavior on color { ColorAnimation { duration: 180 } }

        Rectangle {
            id: thumb
            readonly property real goal: mouse.pressed ? 28 : (root.checked ? 24 : 16)
            width: goal
            height: goal
            radius: Math.min(width, height) / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? track.width - 4 - goal : 8 - (goal - 16) / 2
            color: root.checked ? Theme.onPrimary : Theme.outline

            Behavior on x { SpringAnimation { spring: 4; damping: 0.3 } }
            Behavior on width { SpringAnimation { spring: 4; damping: 0.3 } }
            Behavior on height { SpringAnimation { spring: 4; damping: 0.3 } }
            Behavior on color { ColorAnimation { duration: 180 } }

            Shape {                                       // check mark
                anchors.centerIn: parent
                width: 14
                height: 14
                opacity: root.checked ? 1 : 0
                scale: root.checked ? 1 : 0.4
                preferredRendererType: Shape.CurveRenderer
                Behavior on opacity { NumberAnimation { duration: 140 } }
                Behavior on scale { SpringAnimation { spring: 4; damping: 0.3 } }

                ShapePath {
                    strokeColor: Theme.primary
                    strokeWidth: 2.2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathPolyline { path: [Qt.point(2, 7.5), Qt.point(5.6, 11), Qt.point(12, 3.6)] }
                }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}