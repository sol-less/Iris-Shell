import QtQuick
import QtQuick.Layouts
import Iris

Reveal {
    id: root
    shown: Countdown.active

    readonly property bool lastSeconds: Countdown.running && Countdown.text.length <= 4 && Countdown.text.startsWith("0:0")

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        width: row.implicitWidth + 20
        height: 26
        radius: 13
        color: Countdown.running ? Theme.secondaryContainer : Theme.surfaceContainerHighest
        Behavior on color { ColorAnimation { duration: 200 } }

        SequentialAnimation on scale {                  // the last ten seconds: it pulses
            running: root.lastSeconds
            loops: Animation.Infinite
            NumberAnimation { to: 1.08; duration: 450; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 450; easing.type: Easing.InOutSine }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 8

            RollText {
                text: Countdown.text
                color: root.lastSeconds ? Theme.error : Theme.onSecondaryContainer
                font.family: Config.data.appearance.font
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            WavyBar {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 12
                value: 1 - Countdown.progress
                thickness: 3
                gap: 2
                wavelength: 14
                amplitude: 2
                running: Countdown.running && root.visible
                color: Theme.primary
                handleColor: Theme.primary
                trackColor: Theme.outlineVariant
            }
        }

        MouseArea {                                      // click: pause or resume
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Countdown.toggle()
        }
    }
}