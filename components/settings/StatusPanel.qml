import QtQuick
import QtQuick.Layouts
import Quickshell
import Iris

ColumnLayout {
    id: root
    property var theme: null
    property bool copied: false
    readonly property string fontFamily: Config.data.appearance.font
    spacing: 2

    readonly property var rows: [
        { name: "Iris Theme daemon", ok: root.theme !== null && root.theme.online,
          detail: root.theme !== null && root.theme.online ? "running" : "start it with: iris-theme daemon" },
        { name: "Hyprland", ok: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== "",
          detail: "the wallpaper picker needs it for the cursor position" },
        { name: "cava", ok: Cava.installed, detail: Cava.installed ? "installed" : "not found in PATH" },
        { name: "Music player", ok: Cava.available, detail: Cava.available ? Cava.players.join(", ") : "none detected" },
        { name: "Backlight", ok: Brightness.available, detail: Brightness.available ? Brightness.device : "no device" },
        { name: "Battery", ok: Battery.available, detail: Battery.available ? Battery.percent + "%" : "none" },
        { name: "Network", ok: Network.connected, detail: Network.type },
        { name: "Wallpapers", ok: Wallpapers.total > 0, detail: Wallpapers.total + " in " + Wallpapers.folder },
        { name: "Apps", ok: Applications.count > 0, detail: Applications.count + " listed" },
        { name: "Settings", ok: Config.sections.length > 0,
          detail: Config.sections.length + " sections from " + Config.registryDir }
    ]
    readonly property string report: rows.map(r => (r.ok ? "[ok]  " : "[!!]  ") + r.name + ": " + r.detail).join("\n")

    Timer { id: copiedTimer; interval: 1800; onTriggered: root.copied = false }

    Repeater {
        model: root.rows
        delegate: Rectangle {
            id: card
            required property int index
            required property var modelData
            readonly property bool first: index === 0
            readonly property bool last: index === root.rows.length - 1

            Layout.fillWidth: true
            implicitHeight: 62
            topLeftRadius: first ? 28 : 8
            topRightRadius: first ? 28 : 8
            bottomLeftRadius: last ? 28 : 8
            bottomRightRadius: last ? 28 : 8
            color: Theme.surfaceContainer

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 18
                spacing: 14

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: card.modelData.name
                        color: Theme.onSurface
                        font.family: root.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }
                    Text {
                        Layout.fillWidth: true
                        text: card.modelData.detail
                        color: Theme.onSurfaceVariant
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideMiddle
                    }
                }

                Rectangle {
                    implicitWidth: pill.implicitWidth + 26
                    implicitHeight: 28
                    radius: 14
                    color: card.modelData.ok ? Theme.primaryContainer : Theme.errorContainer
                    Text {
                        id: pill
                        anchors.centerIn: parent
                        text: card.modelData.ok ? "OK" : "Missing"
                        color: card.modelData.ok ? Theme.onPrimaryContainer : Theme.onErrorContainer
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.topMargin: 16
        implicitWidth: copyLabel.implicitWidth + 36
        implicitHeight: 40
        radius: copyPress.pressed ? 12 : 20
        color: Theme.secondaryContainer
        Behavior on radius { Spring {} }

        Text {
            id: copyLabel
            anchors.centerIn: parent
            text: root.copied ? "Copied" : "Copy report"
            color: Theme.onSecondaryContainer
            font.family: root.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        MouseArea {
            id: copyPress
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Quickshell.execDetached(["wl-copy", root.report])
                root.copied = true
                copiedTimer.restart()
            }
        }
    }
}