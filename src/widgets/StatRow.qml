import QtQuick
import QtQuick.Layouts
import Iris

RowLayout {
    id: root
    property string label: ""
    property real value: 0
    property string text: ""
    property bool running: false
    spacing: 10

    Text {
        Layout.preferredWidth: 38
        text: root.label
        color: Theme.onSurfaceVariant
        font.family: Config.data.appearance.font
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }
    WavyBar {
        Layout.fillWidth: true
        Layout.preferredHeight: 16
        value: root.value
        thickness: 4
        gap: 3
        wavelength: 22
        amplitude: 2.5
        running: root.running
        color: root.value > 0.85 ? Theme.error : Theme.primary
        handleColor: color
        trackColor: Theme.surfaceContainerHighest
    }
    Text {
        Layout.preferredWidth: 78
        horizontalAlignment: Text.AlignRight
        text: root.text
        color: Theme.onSurface
        font.family: Config.data.appearance.font
        font.pixelSize: 12
        font.weight: Font.Medium
    }
}