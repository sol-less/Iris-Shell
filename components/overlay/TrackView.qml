import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Iris

Item {
    id: root
    readonly property string fontFamily: Config.data.appearance.font

    implicitWidth: row.implicitWidth + 32
    implicitHeight: 58

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 14

        ClippingRectangle {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            radius: 21
            color: Theme.surfaceContainerHighest
            Image {
                anchors.fill: parent
                source: Hud.trackArt
                sourceSize.width: 84
                sourceSize.height: 84
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
        ColumnLayout {
            spacing: 0
            Text {
                Layout.maximumWidth: 260
                text: Hud.trackTitle
                color: Theme.onSurface
                font.family: root.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.maximumWidth: 260
                text: Hud.trackArtist
                color: Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
        WavyBar {                                        // moves with the music
            Layout.preferredWidth: 38
            Layout.preferredHeight: 18
            value: 1
            thickness: 4
            wavelength: 16
            amplitude: 4 * (0.4 + Cava.level)
            running: root.visible
            color: Theme.primary
            handleColor: Theme.primary
            trackColor: Theme.surfaceContainerHighest
        }
    }
}