import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Iris

Item {
    id: root

    property string kind: "volume"       // "volume" | "brightness"
    property real level: 0               // can exceed 1 (over 100% volume)
    property bool muted: false

    property real squiggle: Hud.squiggle // 0 = straight line, 1 = very wavy
    readonly property string fontFamily: "Inter"

    readonly property bool over: level > 1.0

    readonly property string iconName: kind === "brightness"
        ? "display-brightness-symbolic"
        : (muted || level <= 0 ? "audio-volume-muted-symbolic"
           : level < 0.34 ? "audio-volume-low-symbolic"
           : level < 0.67 ? "audio-volume-medium-symbolic"
           : "audio-volume-high-symbolic")

    // smooth value changes
    property real shown: Math.min(1, level)
    Behavior on shown { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    // 0 when muted, so the wave flattens out
    property real flat: muted ? 0 : 1
    Behavior on flat { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    // pulse: the wave swells and speeds up for a moment when the value changes
    property real boost: 0
    onLevelChanged: { boost = 1; boostAnim.restart() }
    onMutedChanged: { boost = 1; boostAnim.restart() }
    NumberAnimation {
        id: boostAnim
        target: root
        property: "boost"
        to: 0
        duration: 900
        easing.type: Easing.OutCubic
    }

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 36

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        IconImage {
            implicitSize: 18
            opacity: root.muted ? 0.6 : 1
            source: Quickshell.iconPath(root.iconName, "image-missing")
        }

        WavyBar {
            id: wave
            Layout.preferredWidth: 150
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter

            value: root.shown
            thickness: 4
            gap: 3
            wavelength: 36 - 16 * root.squiggle
            amplitude: root.squiggle * 4.5 * root.flat * (1 + 0.35 * root.boost)

            color: root.muted ? Theme.outline : (root.over ? Theme.error : Theme.primary)
            handleColor: color
            trackColor: Theme.surfaceContainerHighest

            Behavior on color { ColorAnimation { duration: 200 } }

            // the travelling wave; runs only while the OSD is visible
            NumberAnimation on phase {
                from: 0
                to: Math.PI * 2
                duration: 1500 / (1 + 1.2 * root.boost)
                loops: Animation.Infinite
                running: root.visible
            }
        }

        Text {
            Layout.preferredWidth: 46
            horizontalAlignment: Text.AlignRight
            text: root.muted ? "Muted" : Math.round(root.level * 100) + "%"
            color: root.muted ? Theme.onSurfaceVariant : Theme.onSurface
            font.family: root.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
    }
}