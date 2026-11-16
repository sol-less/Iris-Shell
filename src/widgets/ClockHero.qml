import QtQuick
import Quickshell
import M3Shapes
import Iris

Rectangle {
    id: root
    implicitHeight: 124
    radius: 36
    color: Theme.tertiaryContainer
    readonly property string fontFamily: Config.data.appearance.font

    SystemClock { id: clock; precision: SystemClock.Minutes }

    MaterialShape {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 92
        shape: MaterialShape.Cookie12Sided
        color: Theme.tertiary
        opacity: 0.32
        NumberAnimation on rotation { from: 0; to: 360; duration: 90000; loops: Animation.Infinite; running: root.visible }
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            text: Qt.formatDateTime(clock.date, Config.data.notch.clock24h ? "HH:mm" : "h:mm AP")
            color: Theme.onTertiaryContainer
            font.family: root.fontFamily
            font.pixelSize: 50
            font.weight: Font.DemiBold
        }
        Text {
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Theme.onTertiaryContainer
            opacity: 0.75
            font.family: root.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
        }
    }
}