import QtQuick
import Iris

Rectangle {
    id: root
    property string text: ""
    property bool accent: false
    signal clicked()

    implicitWidth: lbl.implicitWidth + 30
    implicitHeight: 38
    radius: press.pressed ? 12 : height / 2
    color: accent ? Theme.primary : Theme.secondaryContainer
    scale: press.pressed ? 0.96 : 1
    Behavior on radius { Spring {} }
    Behavior on scale { Spring {} }
    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
        id: lbl
        anchors.centerIn: parent
        text: root.text
        color: root.accent ? Theme.onPrimary : Theme.onSecondaryContainer
        font.family: Config.data.appearance.font
        font.pixelSize: 13
        font.weight: Font.Medium
    }
    MouseArea { id: press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}