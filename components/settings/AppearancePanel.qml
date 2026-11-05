import QtQuick
import QtQuick.Layouts
import Iris

ColumnLayout {
    id: root
    property var theme: null
    readonly property bool ok: theme !== null && theme.online
    readonly property string fontFamily: Config.data.appearance.font
    spacing: 2

    function pretty(s) {
        const t = (s || "").replace("scheme-", "").replace("-", " ")
        return t.charAt(0).toUpperCase() + t.slice(1)
    }

    component Cell: Rectangle {
        property bool first: false
        property bool last: false
        default property alias content: inner.data
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + 34
        topLeftRadius: first ? 28 : 8
        topRightRadius: first ? 28 : 8
        bottomLeftRadius: last ? 28 : 8
        bottomRightRadius: last ? 28 : 8
        color: Theme.surfaceContainer
        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: 22
            anchors.topMargin: 17
            anchors.bottomMargin: 17
        }
    }

    // ----- hero card -----
    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: 18
        implicitHeight: 160
        radius: 32
        color: Theme.tertiaryContainer

        RowLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 22

            Rectangle {                                   // the source color, bounces when it changes
                id: blob
                Layout.preferredWidth: 88
                Layout.preferredHeight: 88
                radius: 44
                color: root.ok && root.theme.source !== "" ? root.theme.source : Theme.outline
                border.width: 4
                border.color: Theme.surface
                onColorChanged: bounce.restart()
                SequentialAnimation {
                    id: bounce
                    NumberAnimation { target: blob; property: "scale"; to: 0.8; duration: 90 }
                    NumberAnimation { target: blob; property: "scale"; to: 1; duration: 420; easing.type: Easing.OutBack }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    text: root.ok ? root.pretty(root.theme.scheme) : "Iris Theme is off"
                    color: Theme.onTertiaryContainer
                    font.family: root.fontFamily
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                }
                Text {
                    text: root.ok ? (root.theme.mode === "dark" ? "Dark" : "Light") + (root.theme.autoMode ? " · automatic" : "")
                                  : "Start it with: iris-theme daemon"
                    color: Theme.onTertiaryContainer
                    opacity: 0.75
                    font.family: root.fontFamily
                    font.pixelSize: 14
                }
                Row {                                     // the live palette
                    Layout.topMargin: 10
                    spacing: 8
                    Repeater {
                        model: [Theme.primary, Theme.secondary, Theme.tertiary, Theme.error,
                                Theme.surfaceContainerHighest, Theme.outline]
                        delegate: Rectangle {
                            required property color modelData
                            width: 26; height: 26; radius: 13
                            color: modelData
                            border.width: 2
                            border.color: Theme.tertiaryContainer
                            Behavior on color { ColorAnimation { duration: 400 } }
                        }
                    }
                }
            }
        }
    }

    // ----- daemon controls -----
    Cell {
        visible: root.ok
        first: true
        SettingRow {
            Layout.fillWidth: true
            title: "Mode"
            description: "Dark or light colors for the shell and your apps"
            Choice {
                options: [{ label: "Dark", value: "dark" }, { label: "Light", value: "light" }]
                current: root.ok ? root.theme.mode : ""
                onPicked: (v) => root.theme.setMode(v)
            }
        }
    }
    Cell {
        visible: root.ok
        SettingRow {
            Layout.fillWidth: true
            title: "Automatic"
            description: "Switch by time of day (the schedule is in iris-theme's config.toml)"
            Toggle {
                checked: root.ok && root.theme.autoMode
                onToggled: (v) => root.theme.setAuto(v)
            }
        }
    }
    Cell {
        visible: root.ok
        last: true
        SettingRow {
            Layout.fillWidth: true
            wide: true
            title: "Color scheme"
            description: "How the palette is built from the wallpaper color"
            Choice {
                options: [
                    { label: "Expressive", value: "scheme-expressive" },
                    { label: "Tonal spot", value: "scheme-tonal-spot" },
                    { label: "Neutral", value: "scheme-neutral" },
                    { label: "Fruit salad", value: "scheme-fruit-salad" },
                    { label: "Rainbow", value: "scheme-rainbow" }
                ]
                current: root.ok ? root.theme.scheme : ""
                onPicked: (v) => root.theme.setScheme(v)
            }
        }
    }
}