import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import M3Shapes
import Iris

Item {
    id: root
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool muted: source && source.audio ? source.audio.muted : false

    GridLayout {
        anchors.fill: parent
        anchors.margins: 12
        columns: root.width >= 320 ? 2 : 1
        columnSpacing: 8
        rowSpacing: 8

        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
            glyph: "D"; title: "Do not disturb"
            subtitle: Hud.dnd ? "On" : (Hud.dndActive ? "Quiet hours" : "Off")
            on: Hud.dndActive
            onClicked: Hud.toggleDnd()
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
            glyph: "C"; title: "Caffeine"
            subtitle: Hud.caffeine ? "Awake" : "Off"
            on: Hud.caffeine
            shapeOn: MaterialShape.Sunny
            onClicked: { Hud.caffeine = !Hud.caffeine; Hud.showToast(Hud.caffeine ? "Caffeine on" : "Caffeine off") }
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
            glyph: "M"; title: "Microphone"
            subtitle: root.muted ? "Muted" : "Live"
            on: root.muted
            shapeOn: MaterialShape.Square
            onClicked: {
                if (!root.source || !root.source.audio) return
                root.source.audio.muted = !root.source.audio.muted
                Hud.showToast(root.source.audio.muted ? "Microphone muted" : "Microphone on")
            }
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
            glyph: "Q"; title: "Quiet hours"
            subtitle: Hud.quietFrom + "–" + Hud.quietTo
            on: Hud.quietEnabled
            shapeOn: MaterialShape.Cookie6Sided
            onClicked: Config.set("notifications.quietEnabled", !Hud.quietEnabled)
        }
    }
}