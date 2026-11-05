import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Iris

Scope {
    id: root

    property var theme: null              // the IrisThemeClient
    property bool open: false
    property int selected: 0
    property string query: ""
    readonly property string fontFamily: Config.data.appearance.font

    // qs ipc call settings toggle
    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
    }

    // ---------- every setting is one entry here ----------
    readonly property var sections: [
        { name: "Appearance", sub: "Colors and fonts", badge: "A", special: "appearance", groups: [
            { title: "Typography", items: [
                { key: "appearance.font", type: "text", placeholder: "Inter", title: "Font family", desc: "Applies to the whole shell right away" }
            ] }
        ] },
        { name: "Notch", sub: "The pill at the top", badge: "N", groups: [
            { title: "Pages", items: [
                { key: "notch.loop", type: "toggle", title: "Loop pages", desc: "Swiping past the last page wraps around to the first" },
                { key: "notch.swipeThreshold", type: "slider", min: 10, max: 120, step: 1, unit: " px", title: "Swipe distance", desc: "How far to drag before the page switches" },
                { key: "notch.dragRange", type: "slider", min: 60, max: 300, step: 5, unit: " px", title: "Drag weight", desc: "Larger feels heavier" }
            ] },
            { title: "Look", items: [
                { key: "notch.radius", type: "slider", min: 4, max: 18, step: 1, unit: " px", title: "Corner radius" },
                { key: "notch.shadow", type: "slider", min: 0, max: 1, step: 0.05, title: "Shadow" },
                { key: "notch.opacity", type: "slider", min: 0.4, max: 1, step: 0.05, title: "Opacity" }
            ] },
            { title: "Indicators", items: [
                { key: "notch.showNetwork", type: "toggle", title: "Network indicator" },
                { key: "notch.showBattery", type: "toggle", title: "Battery indicator" }
            ] }
        ] },
        { name: "Launcher & media", sub: "Notch pages", badge: "L", groups: [
            { title: "Launcher", items: [
                { key: "launcher.iconSize", type: "slider", min: 16, max: 40, step: 1, unit: " px", title: "Icon size" },
                { key: "launcher.maxWidth", type: "slider", min: 160, max: 600, step: 10, unit: " px", title: "Strip width", desc: "The icon strip scrolls beyond this" }
            ] },
            { title: "Media", items: [
                { key: "media.squiggle", type: "slider", min: 0, max: 1, step: 0.05, title: "Progress squiggle", desc: "0 is a straight line" }
            ] }
        ] },
        { name: "OSD & notifications", sub: "Pop-ins in the notch", badge: "O", groups: [
            { title: "On-screen display", items: [
                { key: "osd.volume", type: "toggle", title: "Volume OSD" },
                { key: "osd.brightness", type: "toggle", title: "Brightness OSD" },
                { key: "osd.ms", type: "slider", min: 600, max: 4000, step: 100, unit: " ms", title: "Duration" },
                { key: "osd.squiggle", type: "slider", min: 0, max: 1, step: 0.05, title: "Wave squiggle", desc: "0 is a straight line, 1 is very wavy" },
                { key: "osd.squiggle", type: "wave", title: "Preview" }
            ] },
            { title: "Notifications", items: [
                { key: "notifications.dnd", type: "toggle", title: "Do not disturb", desc: "Notifications are not shown while this is on" },
                { key: "notifications.ms", type: "slider", min: 1500, max: 12000, step: 500, unit: " ms", title: "Duration" },
                { key: "notifications.criticalMs", type: "slider", min: 3000, max: 30000, step: 1000, unit: " ms", title: "Critical duration" }
            ] }
        ] },
        { name: "Apps", sub: "What the launcher lists", badge: "P", groups: [
            { title: "Visibility", items: [
                { key: "apps.includeHidden", type: "toggle", title: "Show hidden entries", desc: "Helpers and apps meant for other desktops" },
                { key: "apps.includeTerminal", type: "toggle", title: "Show terminal apps", desc: "TUI apps and terminal emulators" }
            ] },
            { title: "Filters", items: [
                { key: "apps.excludeNames", type: "tags", title: "Hide by name", desc: "Apps whose name contains one of these words" },
                { key: "apps.excludeCategories", type: "tags", title: "Hide by category", desc: "For example X-SuSE-YaST or Screensaver" }
            ] },
            { title: "Launching", items: [
                { key: "apps.terminal", type: "text", placeholder: "$TERMINAL", title: "Terminal", desc: "Used for terminal apps (empty uses $TERMINAL)" }
            ] }
        ] },
        { name: "Wallpapers", sub: "The picker", badge: "W", groups: [
            { title: "Library", items: [
                { key: "wallpaper.folder", type: "text", title: "Folder", desc: "Where the picker looks for images" },
                { key: "wallpaper.perPage", type: "slider", min: 3, max: 12, step: 1, title: "Wallpapers per page" }
            ] },
            { title: "Picker", items: [
                { key: "wallpaper.tileWidth", type: "slider", min: 100, max: 260, step: 5, unit: " px", title: "Tile size" },
                { key: "wallpaper.dim", type: "slider", min: 0, max: 0.8, step: 0.05, title: "Background dim" },
                { key: "wallpaper.animMs", type: "slider", min: 200, max: 1000, step: 50, unit: " ms", title: "Animation length" }
            ] }
        ] },
        { name: "Cava", sub: "Audio visualizer", badge: "C", groups: [
            { title: "Audio", items: [
                { key: "cava.inputMethod", type: "choice", title: "Audio input",
                  options: [{ label: "Default", value: "" }, { label: "PipeWire", value: "pipewire" },
                            { label: "PulseAudio", value: "pulse" }, { label: "ALSA", value: "alsa" }] },
                { key: "cava.onlyWhenPlaying", type: "toggle", title: "Only while music plays" }
            ] },
            { title: "Visualizer", items: [
                { key: "cava.bars", type: "slider", min: 4, max: 64, step: 1, title: "Bars" },
                { key: "cava.framerate", type: "slider", min: 15, max: 144, step: 1, unit: " fps", title: "Framerate" },
                { key: "cava.barWidth", type: "slider", min: 2, max: 24, step: 1, unit: " px", title: "Bar width" },
                { key: "cava.barSpacing", type: "slider", min: 0, max: 12, step: 1, unit: " px", title: "Bar spacing" }
            ] }
        ] },
        { name: "About", sub: "Files and reset", badge: "i", special: "about", groups: [] }
    ]

    readonly property var current: sections[selected]

    // what the page shows: the selected section, or the search results
    function viewGroups() {
        const q = query.trim().toLowerCase()
        if (q === "") return current.groups ?? []
        const out = []
        for (const s of sections) {
            for (const g of s.groups ?? []) {
                const items = g.items.filter(i => (i.title + " " + (i.desc ?? "") + " " + s.name).toLowerCase().includes(q))
                if (items.length > 0) out.push({ title: s.name + " · " + g.title, items: items })
            }
        }
        return out
    }
    readonly property var groups: viewGroups()
    readonly property bool searching: query.trim() !== ""

    FloatingWindow {
        id: win
        title: "Iris Settings"
        visible: root.open
        color: Theme.surface
        implicitWidth: 980
        implicitHeight: 680
        minimumSize: Qt.size(780, 500)

        onVisibleChanged: if (!visible) root.open = false     // closed with the window's own button

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ================= navigation rail =================
            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 264

                Text {
                    id: railTitle
                    x: 28; y: 30
                    text: "Settings"
                    color: Theme.onSurface
                    font.family: root.fontFamily
                    font.pixelSize: 32
                    font.weight: Font.DemiBold
                }
                Text {
                    anchors.left: railTitle.left
                    anchors.top: railTitle.bottom
                    text: "Iris Shell"
                    color: Theme.onSurfaceVariant
                    font.family: root.fontFamily
                    font.pixelSize: 13
                }

                Item {
                    id: rail
                    x: 16
                    y: 112
                    width: parent.width - 32
                    height: root.sections.length * 56

                    Rectangle {                                // the sliding active indicator
                        width: parent.width
                        height: 52
                        radius: 26
                        color: Theme.secondaryContainer
                        opacity: root.searching ? 0.4 : 1
                        y: root.selected * 56
                        Behavior on y { SpringAnimation { spring: 4; damping: 0.35 } }
                    }

                    Repeater {
                        model: root.sections
                        delegate: Item {
                            id: entry
                            required property int index
                            required property var modelData
                            readonly property bool active: root.selected === index

                            y: index * 56
                            width: rail.width
                            height: 52

                            Rectangle {                        // badge: circle that morphs into a rounded square
                                id: badge
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34; height: 34
                                radius: entry.active ? 11 : 17
                                color: [Theme.primaryContainer, Theme.tertiaryContainer, Theme.secondaryContainer][entry.index % 3]
                                Behavior on radius { SpringAnimation { spring: 5; damping: 0.4 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: entry.modelData.badge
                                    color: [Theme.onPrimaryContainer, Theme.onTertiaryContainer, Theme.onSecondaryContainer][entry.index % 3]
                                    font.family: root.fontFamily
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                }
                            }
                            Text {
                                anchors.left: badge.right
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.modelData.name
                                color: entry.active && !root.searching ? Theme.onSecondaryContainer : Theme.onSurface
                                font.family: root.fontFamily
                                font.pixelSize: 14
                                font.weight: entry.active ? Font.DemiBold : Font.Medium
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { searchInput.text = ""; root.query = ""; root.selected = entry.index }
                            }
                        }
                    }
                }
            }

            // ================= content =================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 24
                Layout.rightMargin: 28
                spacing: 8

                // ----- search bar -----
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: 28
                    color: Theme.surfaceContainerHigh
                    border.width: searchInput.activeFocus ? 2 : 0
                    border.color: Theme.primary

                    Shape {                                    // magnifier
                        x: 22; y: 18
                        width: 20; height: 20
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: Theme.onSurfaceVariant
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            PathAngleArc { centerX: 8.5; centerY: 8.5; radiusX: 6; radiusY: 6; startAngle: 0; sweepAngle: 360 }
                        }
                        ShapePath {
                            strokeColor: Theme.onSurfaceVariant
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 13; startY: 13
                            PathLine { x: 18; y: 18 }
                        }
                    }

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        anchors.leftMargin: 58
                        anchors.rightMargin: 56
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        color: Theme.onSurface
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        onTextChanged: root.query = text

                        Text {
                            visible: searchInput.text === "" && !searchInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search settings"
                            color: Theme.onSurfaceVariant
                            font: searchInput.font
                        }
                    }

                    Rectangle {                                // clear button
                        visible: searchInput.text !== ""
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32; height: 32; radius: 16
                        color: clearHover.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                        Text { anchors.centerIn: parent; text: "×"; color: Theme.onSurfaceVariant; font.pixelSize: 20 }
                        MouseArea { id: clearHover; anchors.fill: parent; hoverEnabled: true; onClicked: searchInput.text = "" }
                    }
                }

                // ----- the page -----
                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: page.implicitHeight + 70
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: page
                        y: 18
                        width: flick.width
                        spacing: 22

                        property real enter: 0
                        NumberAnimation { id: enterAnim; target: page; property: "enter"; from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic }
                        Connections {
                            target: root
                            function onSelectedChanged() { enterAnim.restart() }
                            function onQueryChanged() { enterAnim.restart() }
                        }
                        Component.onCompleted: enterAnim.restart()

                        // heading
                        ColumnLayout {
                            spacing: 2
                            opacity: Math.min(1, page.enter * 2)
                            Text {
                                text: root.searching ? "Search results" : root.current.name
                                color: Theme.onSurface
                                font.family: root.fontFamily
                                font.pixelSize: 36
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: root.searching ? root.groups.length + " matching group" + (root.groups.length === 1 ? "" : "s")
                                                     : root.current.sub
                                color: Theme.onSurfaceVariant
                                font.family: root.fontFamily
                                font.pixelSize: 14
                            }
                        }

                        Loader {                               // Appearance / About panels
                            Layout.fillWidth: true
                            active: !root.searching && root.current.special !== undefined
                            sourceComponent: root.current.special === "about" ? aboutC : appearanceC
                            opacity: Math.min(1, page.enter * 1.8)
                        }

                        Repeater {
                            model: root.groups
                            delegate: SettingGroup {
                                required property int index
                                required property var modelData
                                title: modelData.title
                                items: modelData.items
                                Layout.fillWidth: true
                                opacity: Math.max(0, Math.min(1, page.enter * 1.8 - index * 0.2))
                                transform: Translate { y: (1 - parent.opacity) * 26 }
                            }
                        }

                        Rectangle {                            // reset this page
                            visible: !root.searching && (root.current.groups ?? []).length > 0
                            implicitWidth: resetLabel.implicitWidth + 36
                            implicitHeight: 40
                            radius: resetPress.pressed ? 12 : 20
                            color: Theme.secondaryContainer
                            Behavior on radius { SpringAnimation { spring: 6; damping: 0.4 } }
                            Text {
                                id: resetLabel
                                anchors.centerIn: parent
                                text: "Reset " + root.current.name
                                color: Theme.onSecondaryContainer
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                            MouseArea {
                                id: resetPress
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { 
                                    for (const g of root.current.groups) for (const it of g.items) Config.reset(it.key)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component { id: appearanceC; AppearancePanel { theme: root.theme } }
    Component { id: aboutC; AboutPanel { theme: root.theme } }
}