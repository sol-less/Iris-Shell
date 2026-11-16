import QtQuick
import QtQuick.Layouts
import Iris

Rectangle {
    id: root
    property var sink: null
    readonly property string fontFamily: Config.data.appearance.font

    implicitHeight: 118
    radius: 28
    color: Theme.surfaceContainerHigh

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                Layout.preferredWidth: 72
                text: "Volume"
                color: Theme.onSurface
                font.family: root.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            ValueSlider {
                Layout.fillWidth: true
                from: 0; to: 100; step: 1; unit: "%"
                value: root.sink && root.sink.audio ? Math.round(root.sink.audio.volume * 100) : 0
                onMoved: (v) => { if (root.sink && root.sink.audio) root.sink.audio.volume = v / 100 }
            }
            Chip {
                text: "Mute"
                accent: root.sink && root.sink.audio ? root.sink.audio.muted : false
                onClicked: { if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                Layout.preferredWidth: 72
                text: "Brightness"
                color: Brightness.available ? Theme.onSurface : Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            ValueSlider {
                Layout.fillWidth: true
                enabled: Brightness.available
                opacity: Brightness.available ? 1 : 0.4
                from: 1; to: 100; step: 1; unit: "%"
                value: Math.round(Brightness.level * 100)
                onMoved: (v) => Brightness.setLevel(v / 100)
            }
        }
    }
}