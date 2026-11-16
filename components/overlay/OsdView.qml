import QtQuick
import QtQuick.Layouts
import M3Shapes
import Iris

Item {
    id: root

    property string kind: "volume"       // "volume" | "brightness"
    property real level: 0
    property bool muted: false

    readonly property string fontFamily: Config.data.appearance.font
    readonly property bool bright: kind === "brightness"

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t)
    }

    readonly property color accent: mix(mix(bright ? Theme.tertiary : Theme.primary, Theme.outline, Hud.osdMute),
                                        Theme.error, Hud.osdOver)
    readonly property color container: mix(mix(bright ? Theme.tertiaryContainer : Theme.primaryContainer,
                                               Theme.surfaceContainerHighest, Hud.osdMute),
                                           Theme.errorContainer, Hud.osdOver)
    readonly property color onContainer: mix(mix(bright ? Theme.onTertiaryContainer : Theme.onPrimaryContainer,
                                                 Theme.onSurfaceVariant, Hud.osdMute),
                                             Theme.onErrorContainer, Hud.osdOver)

    implicitWidth: row.implicitWidth + 26
    implicitHeight: 56

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 18
        spacing: 14

        MaterialShape {                                          // morphs between shapes in C++
            Layout.alignment: Qt.AlignVCenter
            implicitSize: 42
            shape: root.bright ? MaterialShape.Sunny
                 : root.muted ? MaterialShape.Square
                 : root.level > 1.0 ? MaterialShape.SoftBurst
                 : MaterialShape.Circle
            color: root.container
            scale: 1 + 0.12 * Hud.osdBoost

            OsdIcon {
                anchors.centerIn: parent
                kind: root.kind
                level: root.level
                muted: root.muted
                color: root.onContainer
            }
        }

        WavyBar {
            Layout.preferredWidth: 160
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignVCenter

            value: Hud.osdShown
            thickness: 5
            gap: 3
            wavelength: 36 - 16 * Hud.squiggle
            amplitude: Hud.squiggle * 5 * (1 - Hud.osdMute) * (1 + 0.35 * Hud.osdBoost)
            phase: Hud.osdPhase

            color: root.accent
            handleColor: root.accent
            trackColor: Theme.surfaceContainerHighest
        }

        Text {
            Layout.preferredWidth: 48
            horizontalAlignment: Text.AlignRight
            text: root.muted ? "Muted" : Math.round(root.level * 100) + "%"
            color: root.muted ? Theme.onSurfaceVariant : Theme.onSurface
            font.family: root.fontFamily
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }
    }
}