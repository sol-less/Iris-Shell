import QtQuick
import QtQuick.Layouts
import Iris

Rectangle {
    id: root
    property bool active: false                          // the panel is open
    readonly property string fontFamily: Config.data.appearance.font

    implicitHeight: 94
    radius: 28
    color: Theme.surfaceContainerHigh

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: Countdown.active && Countdown.label !== "" ? Countdown.label : "Timer"
                color: Theme.onSurface
                font.family: root.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: Countdown.active
                text: Countdown.text
                color: Theme.primary
                font.family: root.fontFamily
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }
        }

        RowLayout {                                      // not running: pick a length
            visible: !Countdown.active
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: [5, 10, 25, 45]
                delegate: Chip {
                    required property int modelData
                    Layout.fillWidth: true
                    text: modelData + " min"
                    onClicked: Countdown.start(modelData)
                }
            }
        }

        RowLayout {                                      // running: progress and controls
            visible: Countdown.active
            Layout.fillWidth: true
            spacing: 6
            WavyBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                value: 1 - Countdown.progress
                thickness: 4
                amplitude: 3
                wavelength: 24
                running: Countdown.running && root.active
                color: Theme.primary
                handleColor: Theme.primary
                trackColor: Theme.surfaceContainerHighest
            }
            Chip { text: Countdown.running ? "Pause" : "Resume"; onClicked: Countdown.toggle() }
            Chip { text: "+5"; onClicked: Countdown.addMinutes(5) }
            Chip { text: "Stop"; onClicked: Countdown.cancel() }
        }
    }
}