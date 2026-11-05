import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string kind: "volume"       // "volume" | "brightness"
    property real level: 0               // 0 to 1 (volume can go above)
    property bool muted: false
    property color color: "white"

    readonly property color none: "transparent"
    readonly property real lv: Math.min(1, level)

    implicitWidth: 18
    implicitHeight: 18

    // ---------- speaker ----------
    Shape {
        visible: root.kind === "volume"
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {                                   // the speaker body
            fillColor: root.color
            strokeColor: root.none
            PathPolyline {
                path: [Qt.point(1.5, 7), Qt.point(5, 7), Qt.point(9, 3.2), Qt.point(9, 14.8),
                       Qt.point(5, 11), Qt.point(1.5, 11), Qt.point(1.5, 7)]
            }
        }
        ShapePath {                                   // wave 1
            strokeColor: !root.muted && root.level > 0 ? root.color : root.none
            strokeWidth: 1.6
            fillColor: root.none
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 9; centerY: 9; radiusX: 3.6; radiusY: 3.6; startAngle: -45; sweepAngle: 90 }
        }
        ShapePath {                                   // wave 2
            strokeColor: !root.muted && root.level > 0.4 ? root.color : root.none
            strokeWidth: 1.6
            fillColor: root.none
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 9; centerY: 9; radiusX: 6.0; radiusY: 6.0; startAngle: -45; sweepAngle: 90 }
        }
        ShapePath {                                   // wave 3
            strokeColor: !root.muted && root.level > 0.75 ? root.color : root.none
            strokeWidth: 1.6
            fillColor: root.none
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 9; centerY: 9; radiusX: 8.2; radiusY: 8.2; startAngle: -45; sweepAngle: 90 }
        }
        ShapePath {                                   // the cross when muted
            strokeColor: root.muted ? root.color : root.none
            strokeWidth: 1.6
            fillColor: root.none
            capStyle: ShapePath.RoundCap
            startX: 12.2; startY: 6.6
            PathLine { x: 16.6; y: 11.4 }
            PathMove { x: 16.6; y: 6.6 }
            PathLine { x: 12.2; y: 11.4 }
        }
    }

    // ---------- sun: the disc and the rays grow with the brightness ----------
    Item {
        visible: root.kind === "brightness"
        anchors.fill: parent

        Rectangle {
            anchors.centerIn: parent
            width: 6 + 2 * root.lv
            height: width
            radius: width / 2
            color: root.color
        }

        Repeater {
            model: 8
            Item {
                required property int index
                anchors.fill: parent
                rotation: index * 45

                Rectangle {
                    x: 8.2
                    y: 0.8
                    width: 1.6
                    height: 1.4 + 1.8 * root.lv
                    radius: 0.8
                    color: root.color
                    opacity: 0.4 + 0.6 * root.lv
                }
            }
        }
    }
}