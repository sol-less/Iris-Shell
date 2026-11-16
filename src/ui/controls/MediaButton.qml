import QtQuick
import QtQuick.Shapes
import M3Shapes
import Iris

Item {
    id: root
    property string kind: "play"
    property bool filled: false
    signal clicked()

    readonly property color ink: filled ? Theme.onPrimary : Theme.onSurface

    implicitWidth: 34
    implicitHeight: 34
    scale: press.pressed ? 0.88 : 1
    Behavior on scale { Spring {} }

    MaterialShape {
        anchors.centerIn: parent
        implicitSize: root.filled ? 34 : 30
        shape: root.filled && root.kind === "pause" ? MaterialShape.Cookie6Sided : MaterialShape.Circle
        color: root.filled ? Theme.primary : (hover.hovered ? Theme.surfaceContainerHighest : "transparent")
    }

    Shape {
        visible: root.kind !== "pause"
        anchors.centerIn: parent
        width: 14; height: 14
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.ink
            strokeColor: "transparent"
            PathPolyline {
                path: root.kind === "prev" ? [Qt.point(12.2, 1.6), Qt.point(4.4, 7), Qt.point(12.2, 12.4)]
                    : root.kind === "next" ? [Qt.point(1.8, 1.6), Qt.point(9.6, 7), Qt.point(1.8, 12.4)]
                    : [Qt.point(3.2, 1.4), Qt.point(12.6, 7), Qt.point(3.2, 12.6)]
            }
        }
        ShapePath {
            fillColor: root.kind === "prev" || root.kind === "next" ? root.ink : "transparent"
            strokeColor: "transparent"
            PathPolyline {
                path: root.kind === "prev"
                    ? [Qt.point(1.4, 1.8), Qt.point(3.4, 1.8), Qt.point(3.4, 12.2), Qt.point(1.4, 12.2)]
                    : [Qt.point(10.6, 1.8), Qt.point(12.6, 1.8), Qt.point(12.6, 12.2), Qt.point(10.6, 12.2)]
            }
        }
    }

    Row {
        visible: root.kind === "pause"
        anchors.centerIn: parent
        spacing: 3
        Rectangle { width: 3.4; height: 12; radius: 1.7; color: root.ink }
        Rectangle { width: 3.4; height: 12; radius: 1.7; color: root.ink }
    }

    HoverHandler { id: hover }
    MouseArea { id: press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}