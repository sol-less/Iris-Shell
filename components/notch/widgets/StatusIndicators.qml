import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Services.Pipewire
import M3Shapes
import Iris

RowLayout {
    id: root
    spacing: 8
    Layout.rightMargin: 8

    property bool showNetwork: true
    property bool showBattery: true

    readonly property string fontFamily: Config.data.appearance.font
    readonly property color okColor: Theme.primary
    readonly property color chargeColor: "#57d36b"
    readonly property color warnColor: "#f5c451"
    readonly property color badColor: Theme.error
    readonly property var mic: Pipewire.defaultAudioSource
    readonly property bool micMuted: mic && mic.audio ? mic.audio.muted : false

    HoverHandler { id: hover }
    readonly property bool expanded: hover.hovered

    Reveal {
        shown: Hud.dndActive
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: dndLabel.implicitWidth + 14
            height: 18
            radius: 9
            color: Theme.tertiaryContainer
            Text {
                id: dndLabel
                anchors.centerIn: parent
                text: "DND" + (Hud.missed > 0 ? " · " + Hud.missed : "")
                color: Theme.onTertiaryContainer
                font.family: root.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
            }
        }
    }

    Reveal {
        shown: Hud.caffeine && Config.data.notch.showCaffeine
        MaterialShape {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 16
            shape: MaterialShape.Sunny
            color: Theme.tertiary
            NumberAnimation on rotation { from: 0; to: 360; duration: 14000; loops: Animation.Infinite; running: root.visible }
        }
    }

    Reveal {
        shown: root.micMuted && Config.data.notch.showMic
        MaterialShape {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 18
            shape: MaterialShape.Square
            color: Theme.error
            Text {
                anchors.centerIn: parent
                text: "M"
                color: Theme.onError
                font.family: root.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
            }
        }
    }

    Reveal {
        shown: root.showNetwork
        Row {
            anchors.verticalCenter: parent.verticalCenter

            Item {
                id: net
                width: 16
                height: 13
                readonly property bool wired: Network.type === "ethernet"
                readonly property int lit: Network.connected && Network.type === "wifi" ? Math.max(1, Math.ceil(Network.signal / 34)) : 0

                Shape {
                    visible: !net.wired
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: net.lit >= 1 ? root.okColor : Theme.outlineVariant
                        strokeWidth: 1.8; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                        PathAngleArc { centerX: 8; centerY: 11; radiusX: 3.6; radiusY: 3.6; startAngle: -135; sweepAngle: 90 }
                    }
                    ShapePath {
                        strokeColor: net.lit >= 2 ? root.okColor : Theme.outlineVariant
                        strokeWidth: 1.8; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                        PathAngleArc { centerX: 8; centerY: 11; radiusX: 6.6; radiusY: 6.6; startAngle: -135; sweepAngle: 90 }
                    }
                    ShapePath {
                        strokeColor: net.lit >= 3 ? root.okColor : Theme.outlineVariant
                        strokeWidth: 1.8; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                        PathAngleArc { centerX: 8; centerY: 11; radiusX: 9.6; radiusY: 9.6; startAngle: -135; sweepAngle: 90 }
                    }
                }
                Rectangle {
                    visible: !net.wired
                    x: 6.7; y: 9.7
                    width: 2.6; height: 2.6; radius: 1.3
                    color: Network.connected ? root.okColor : Theme.outlineVariant
                }
                Rectangle {                                              // offline slash
                    visible: !Network.connected
                    anchors.centerIn: parent
                    width: 18; height: 1.8; radius: 1
                    rotation: 40
                    color: root.badColor
                }
                Rectangle {                                              // ethernet port
                    visible: net.wired
                    anchors.centerIn: parent
                    width: 14; height: 10; radius: 2.5
                    color: "transparent"
                    border.width: 1.4
                    border.color: root.okColor
                    Row {
                        anchors.centerIn: parent
                        spacing: 1.8
                        Repeater { model: 3; Rectangle { width: 1.4; height: 4; radius: 0.7; color: root.okColor } }
                    }
                }
            }

            Item {                                                       // details on hover
                width: root.expanded ? netLabel.implicitWidth + 6 : 0
                height: 13
                clip: true
                Behavior on width { Spring {} }
                Text {
                    id: netLabel
                    x: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: !Network.connected ? "Offline" : (net.wired ? "Wired" : Network.signal + "%")
                    color: Network.connected ? Theme.onSurface : Theme.onSurfaceVariant
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
        }
    }

    Reveal {
        shown: root.showBattery && Battery.available
        Row {
            anchors.verticalCenter: parent.verticalCenter

            Item {
                id: bat
                width: 25
                height: 13
                readonly property bool low: Battery.percent <= 20 && !Battery.charging && !Battery.full
                property real pulse: 1

                SequentialAnimation on pulse {
                    loops: Animation.Infinite
                    running: bat.low || Battery.charging
                    NumberAnimation { to: bat.low ? 0.4 : 0.75; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                    onRunningChanged: if (!running) bat.pulse = 1
                }

                Rectangle {
                    id: shell
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22; height: 12; radius: 4
                    color: "transparent"
                    border.width: 1.2
                    border.color: Theme.onSurfaceVariant

                    Rectangle {                                          // the fill, with a sheen while charging
                        x: 2; y: 2
                        height: parent.height - 4
                        width: Math.max(3, (parent.width - 4) * Battery.percent / 100)
                        radius: 2.2
                        clip: true
                        color: Battery.charging ? root.chargeColor
                             : Battery.percent <= 10 ? root.badColor
                             : Battery.percent <= 20 ? root.warnColor : root.okColor
                        opacity: bat.pulse
                        Behavior on width { Spring {} }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            width: 8
                            height: parent.height
                            opacity: 0.35
                            color: "white"
                            visible: Battery.charging
                            NumberAnimation on x { from: -8; to: 24; duration: 1500; loops: Animation.Infinite; running: Battery.charging && root.visible }
                        }
                    }
                    Shape {                                              // bolt
                        visible: Battery.charging && !Battery.full
                        anchors.fill: parent
                        ShapePath {
                            fillColor: Theme.surface
                            strokeColor: "transparent"
                            PathPolyline {
                                path: [Qt.point(12.4, 1.8), Qt.point(7.8, 6.6), Qt.point(10.6, 6.6), Qt.point(9.4, 10.2),
                                       Qt.point(14.2, 5.2), Qt.point(11.4, 5.2), Qt.point(12.4, 1.8)]
                            }
                        }
                    }
                }
                Rectangle {                                              // nub
                    x: 22.6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2; height: 4.5; radius: 1
                    color: Theme.onSurfaceVariant
                    opacity: 0.85
                }
            }

            Item {                                                       // percent: always when low or charging, else on hover
                width: (root.expanded || bat.low || Battery.charging) ? batLabel.implicitWidth + 5 : 0
                height: 13
                clip: true
                Behavior on width { Spring {} }
                RollText {
                    id: batLabel
                    x: 5
                    anchors.verticalCenter: parent.verticalCenter
                    text: Battery.percent + "%"
                    color: bat.low ? root.badColor : Theme.onSurface
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
        }
    }
}