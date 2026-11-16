import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Widgets
import M3Shapes
import Iris

Item {
    id: root

    property var info: ({})
    property bool shaped: true
    property bool active: false          // hovered or selected
    property bool current: false         // the wallpaper that is set right now
    signal clicked()
    signal entered()
    signal exited()
    signal scrolled(real delta)

    readonly property color halo: current && !active ? Theme.tertiary
                                  : (info.dominant && info.dominant.a > 0 ? info.dominant : Theme.primary)

    scale: active ? 1.12 : 1
    Behavior on scale { Spring {} }

    Item {
        visible: root.shaped
        anchors.fill: parent

        MaterialShape {                                      // color halo behind the tile
            anchors.centerIn: parent
            implicitSize: parent.width * 1.16
            shape: root.active ? MaterialShape.Cookie9Sided : MaterialShape.Square
            color: root.halo
            opacity: root.active ? 0.55 : (root.current ? 0.9 : 0)
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        Image {
            id: img
            anchors.fill: parent
            visible: false
            source: root.shaped ? (root.info.thumb ?? "") : ""
            sourceSize.width: 320
            sourceSize.height: 320
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        Item {
            id: maskItem
            anchors.fill: parent
            visible: false
            layer.enabled: true
            MaterialShape {
                anchors.fill: parent
                shape: root.active ? MaterialShape.Cookie9Sided : MaterialShape.Square
                color: "white"
            }
        }
        MultiEffect {
            anchors.fill: parent
            source: img
            maskEnabled: true
            maskSource: maskItem
        }
    }

    ClippingRectangle {
        visible: !root.shaped
        anchors.fill: parent
        radius: root.active ? 22 : 14
        color: Theme.surfaceContainer
        border.width: root.active || root.current ? 3 : 0
        border.color: root.halo
        Behavior on radius { Spring {} }

        Image {
            anchors.fill: parent
            source: !root.shaped ? (root.info.thumb ?? "") : ""
            sourceSize.width: 480
            sourceSize.height: 270
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onEntered: root.entered()
        onExited: root.exited()
        onWheel: (w) => root.scrolled(w.angleDelta.y !== 0 ? w.angleDelta.y : w.angleDelta.x)
    }

    Rectangle {
        id: star
        visible: root.active || root.info.favorite === true
        anchors.top: parent.top
        anchors.right: parent.right
        width: 28
        height: 28
        radius: 14
        color: Theme.surfaceContainerHigh
        scale: starMouse.pressed ? 0.85 : 1
        Behavior on scale { Spring {} }

        Shape {
            anchors.centerIn: parent
            width: 14
            height: 14
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: root.info.favorite ? Theme.tertiary : "transparent"
                strokeColor: root.info.favorite ? Theme.tertiary : Theme.onSurfaceVariant
                strokeWidth: 1.4
                joinStyle: ShapePath.RoundJoin
                PathPolyline {
                    path: [Qt.point(7, 0.8), Qt.point(8.9, 5), Qt.point(13.4, 5.4), Qt.point(10, 8.4),
                           Qt.point(11, 12.8), Qt.point(7, 10.5), Qt.point(3, 12.8), Qt.point(4, 8.4),
                           Qt.point(0.6, 5.4), Qt.point(5.1, 5), Qt.point(7, 0.8)]
                }
            }
        }
        MouseArea {
            id: starMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Wallpapers.toggleFavorite(root.info.path)
        }
    }
}