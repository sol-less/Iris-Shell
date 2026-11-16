import QtQuick
import Iris

Rectangle {
    id: chip

    property real u: 1
    property string fontFamily: Config.data.appearance.font
    property string text: ""
    property bool confirm: false            // Restart and Shut down need a second tap
    property bool armed: false
    signal activated()

    implicitWidth: lbl.implicitWidth + u * 34
    implicitHeight: u * 40
    radius: press.pressed ? u * 10 : height / 2
    color: armed ? Theme.errorContainer : Theme.secondaryContainer
    Behavior on radius { Spring {} }
    Behavior on color { ColorAnimation { duration: 150 } }

    Timer { id: disarm; interval: 2500; onTriggered: chip.armed = false }

    Text {
        id: lbl
        anchors.centerIn: parent
        text: chip.armed ? "Tap again" : chip.text
        color: chip.armed ? Theme.onErrorContainer : Theme.onSecondaryContainer
        font.family: chip.fontFamily
        font.pixelSize: chip.u * 13
        font.weight: Font.Medium
    }

    MouseArea {
        id: press
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (chip.confirm && !chip.armed) { chip.armed = true; disarm.restart() }
            else { chip.armed = false; chip.activated() }
        }
    }
}