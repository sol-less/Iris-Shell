import Iris
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

RowLayout {
    id: root

    property bool showNetwork: true
    property bool showBattery: true
    readonly property string fontFamily: "Inter"
    readonly property bool expanded: hover.hovered

    spacing: 10
    Layout.rightMargin: 8

    HoverHandler {
        id: hover
    }

    // ================= network =================
    RowLayout {
        id: net

        readonly property bool wifi: Network.type === "wifi"
        readonly property bool wired: Network.type === "ethernet"
        readonly property int lit: Network.connected && wifi ? Math.max(1, Math.ceil(Network.signal / 34)) : 0

        visible: root.showNetwork
        spacing: 0
        Layout.alignment: Qt.AlignVCenter

        Item {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 13

            // wifi fan (also shown dim + slashed when offline)
            Shape {
                visible: !net.wired
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: net.lit >= 1 ? Theme.primary : Theme.outlineVariant
                    strokeWidth: 1.8
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 8
                        centerY: 11
                        radiusX: 3.6
                        radiusY: 3.6
                        startAngle: -135
                        sweepAngle: 90
                    }

                }

                ShapePath {
                    strokeColor: net.lit >= 2 ? Theme.primary : Theme.outlineVariant
                    strokeWidth: 1.8
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 8
                        centerY: 11
                        radiusX: 6.6
                        radiusY: 6.6
                        startAngle: -135
                        sweepAngle: 90
                    }

                }

                ShapePath {
                    strokeColor: net.lit >= 3 ? Theme.primary : Theme.outlineVariant
                    strokeWidth: 1.8
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 8
                        centerY: 11
                        radiusX: 9.6
                        radiusY: 9.6
                        startAngle: -135
                        sweepAngle: 90
                    }

                }

            }

            Rectangle {
                visible: !net.wired
                x: 6.7
                y: 9.7
                width: 2.6
                height: 2.6
                radius: 1.3
                color: Network.connected ? Theme.primary : Theme.outlineVariant
            }
            // offline slash

            Rectangle {
                visible: !Network.connected
                anchors.centerIn: parent
                width: 18
                height: 1.8
                radius: 1
                rotation: 40
                color: Theme.error
            }

            // ethernet port
            Rectangle {
                visible: net.wired
                anchors.centerIn: parent
                width: 14
                height: 10
                radius: 2.5
                color: "transparent"
                border.width: 1.4
                border.color: Theme.onSurface

                Row {
                    anchors.centerIn: parent
                    spacing: 1.8

                    Repeater {
                        model: 3

                        Rectangle {
                            width: 1.4
                            height: 4
                            radius: 0.7
                            color: Theme.onSurface
                        }

                    }

                }

            }

        }

        // details on hover
        Item {
            Layout.preferredWidth: root.expanded ? netLabel.implicitWidth + 6 : 0
            Layout.preferredHeight: 13
            clip: true

            Text {
                id: netLabel

                x: 6
                anchors.verticalCenter: parent.verticalCenter
                text: !Network.connected ? "Offline" : (net.wired ? "Wired" : Network.signal + "%")
                color: Network.connected ? Theme.primary : Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
            }

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    // ================= battery =================
    RowLayout {
        id: bat

        readonly property bool low: Battery.percent <= 20 && !Battery.charging && !Battery.full
        readonly property bool showText: root.expanded || low || Battery.charging
        property real pulse: 1

        visible: root.showBattery && Battery.available
        spacing: 0
        Layout.alignment: Qt.AlignVCenter

        Item {
            Layout.preferredWidth: 25
            Layout.preferredHeight: 13

            Rectangle {
                id: shell

                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 12
                radius: 4
                color: "transparent"
                border.width: 1.2
                border.color: Theme.onSurfaceVariant
                opacity: 0.85

                Rectangle {
                    x: 2
                    y: 2
                    height: parent.height - 4
                    width: Math.max(3, (parent.width - 4) * Battery.percent / 100)
                    radius: 2.2
                    color: bat.low ? Theme.error : (Battery.charging ? Theme.tertiary : Theme.primary)
                    opacity: bat.pulse

                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }

                    }

                }

                // charging bolt
                Shape {
                    visible: Battery.charging && !Battery.full
                    anchors.fill: parent

                    ShapePath {
                        fillColor: Theme.surface
                        strokeColor: "transparent"

                        PathPolyline {
                            path: [Qt.point(12.4, 1.8), Qt.point(7.8, 6.6), Qt.point(10.6, 6.6), Qt.point(9.4, 10.2), Qt.point(14.2, 5.2), Qt.point(11.4, 5.2), Qt.point(12.4, 1.8)]
                        }

                    }

                }

            }
            // nub

            Rectangle {
                x: 22.6
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: 4.5
                radius: 1
                color: Theme.onSurfaceVariant
                opacity: 0.85
            }

        }

        Item {
            Layout.preferredWidth: bat.showText ? batLabel.implicitWidth + 5 : 0
            Layout.preferredHeight: 13
            clip: true

            Text {
                id: batLabel

                x: 5
                anchors.verticalCenter: parent.verticalCenter
                text: Battery.percent + "%"
                color: bat.low ? Theme.error : Theme.primary
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
            }

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

        }

        SequentialAnimation on pulse {
            loops: Animation.Infinite
            running: bat.low || Battery.charging
            onRunningChanged: {
                if (!running) {
                    bat.pulse = 1;
                }
            }

            NumberAnimation {
                to: bat.low ? 0.4 : 0.75
                duration: 900
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: 1
                duration: 900
                easing.type: Easing.InOutSine
            }

        }

    }

    component Arc: ShapePath {
        property real r: 4
        property bool on: false

        strokeColor: on ? Theme.onSurface : Theme.outlineVariant
        strokeWidth: 1.8
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap

        PathAngleArc {
            centerX: 8
            centerY: 11
            radiusX: r
            radiusY: r
            startAngle: -135
            sweepAngle: 90
        }

    }

}
