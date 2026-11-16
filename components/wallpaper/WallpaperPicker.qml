pragma ComponentBehavior: Bound
import Iris
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property var theme: null                                   // the IrisThemeClient
    property int perPage: Config.data.wallpaper.perPage
    readonly property bool shaped: Config.data.wallpaper.shaped
    readonly property int tileW: shaped ? Math.round(Config.data.wallpaper.tileWidth * 0.8) : Config.data.wallpaper.tileWidth
    readonly property int tileH: shaped ? tileW : Math.round(tileW * 0.56)    // shaped tiles are square
    property real nudge: 0                  // the fan tilts with the scroll, then snaps
    Behavior on nudge { Spring {} }

    property bool open: false
    property bool blocked: false
    property string monitor: ""
    property real cursorX: 0
    property real cursorY: 0
    property int page: 0                  // the page we are going to
    property int shownPage: 0             // the page whose tiles are on screen
    property int sel: -1
    property var hover: null              // the hovered or selected wallpaper
    property string lastPreview: ""
    property string pickedUrl: ""
    property real reveal: 0               // 0 to 1: the chosen wallpaper fills the screen

    property real progress: open ? 1 : 0
    Behavior on progress { Spring {} }

    property real swap: 1
    property int dir: 1
    property real spin: 0
    onBlockedChanged: if (blocked) open = false
    onPageChanged: {
        if (page === shownPage) return
        dir = page > shownPage ? 1 : -1
        swapAnim.restart()
    }
    SequentialAnimation {
        id: swapAnim
        ScriptAction { script: root.spin = root.dir }
        NumberAnimation { target: root; property: "swap"; to: 0; duration: 170; easing.type: Easing.InCubic }
        ScriptAction { script: { root.shownPage = root.page; root.spin = -root.dir } }
        NumberAnimation { target: root; property: "swap"; to: 1; duration: 420; easing.type: Easing.OutCubic }
    }

    onHoverChanged: if (hover) lastPreview = hover.thumb

    function toggle() {
        if (blocked) return
        if (open) { open = false; return }
        const c = Wallpapers.cursor()
        if (!c.ok) return                                      // not running under Hyprland
        monitor = c.monitor
        cursorX = c.x
        cursorY = c.y
        swapAnim.stop()
        swap = 1
        shownPage = 0
        page = 0
        sel = -1
        hover = null
        pickedUrl = ""
        reveal = 0
        Wallpapers.query = ""
        open = true
    }

    function back() {                                          // Escape: clear the search first, then close
        if (Wallpapers.query !== "") Wallpapers.query = ""
        else open = false
    }

    function pick(info) {
        if (reveal > 0 || !info.path) return
        pickedUrl = info.thumb
        Wallpapers.apply(info.path)
        if (theme && theme.online) theme.setImage(info.path)
        else Quickshell.execDetached(["iris-theme", "image", info.path, "--source-color-index", "0"])
        revealAnim.restart()
    }
    NumberAnimation {
        id: revealAnim
        target: root
        property: "reveal"
        from: 0; to: 1
        duration: 480
        easing.type: Easing.OutCubic
        onFinished: { root.open = false; root.reveal = 0; root.pickedUrl = "" }
    }

    function cycleCategory(d) {
        const cats = ["all", "fav"].concat(Wallpapers.categories.map(c => "c:" + c))
        const cur = Wallpapers.favoritesOnly ? "fav" : (Wallpapers.category !== "" ? "c:" + Wallpapers.category : "all")
        const next = cats[(cats.indexOf(cur) + d + cats.length) % cats.length]
        Wallpapers.favoritesOnly = next === "fav"
        Wallpapers.category = next.startsWith("c:") ? next.substring(2) : ""
    }

    Connections {
        target: Wallpapers
        function onQueryChanged() { root.page = 0; root.shownPage = 0; root.sel = -1; root.hover = null }
        function onCategoryChanged() { root.page = 0; root.shownPage = 0; root.sel = -1; root.hover = null }
        function onFavoritesOnlyChanged() { root.page = 0; root.shownPage = 0; root.sel = -1; root.hover = null }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.toggle() }
        function close(): void { root.open = false }
        function random(): void {
            if (Wallpapers.count === 0) return
            const info = Wallpapers.get(Math.floor(Math.random() * Wallpapers.count))
            Wallpapers.apply(info.path)
            if (root.theme && root.theme.online) root.theme.setImage(info.path)
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            visible: root.progress > 0.001 && modelData.name === root.monitor
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "iris-wallpaper"
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors { top: true; bottom: true; left: true; right: true }

            property var slots: Wallpapers.ringSlots(root.cursorX, root.cursorY, width, height - 120,
                                                     root.tileW * (root.shaped ? 1.1 : 1), root.tileH)
            readonly property int per: Math.max(1, Math.min(root.perPage, slots.length))
            readonly property int pages: Math.max(1, Math.ceil(Wallpapers.count / per))
            readonly property int visibleCount: Math.min(slots.length, per, Math.max(0, Wallpapers.count - root.page * per))

            property real acc: 0
            property bool locked: false

            function turn(d) {                                  // d < 0: next page
                root.page = Math.max(0, Math.min(pages - 1, root.page + (d < 0 ? 1 : -1)))
            }

            function scroll(d) {
                if (Config.data.wallpaper.naturalScroll) d = -d
                if (Math.abs(d) >= 100) {
                    if (!notchTimer.running) { turn(d); notchTimer.restart() }
                    return
                }
                quiet.restart()
                if (locked) return
                acc += d
                root.nudge = Math.max(-1, Math.min(1, acc / 200))
                if (Math.abs(acc) >= Config.data.wallpaper.scrollSensitivity) {
                    turn(acc)
                    acc = 0
                    root.nudge = 0
                    locked = true
                }
            }
            Timer { id: notchTimer; interval: 130 }
            Timer { id: quiet; interval: 170; onTriggered: { win.acc = 0; win.locked = false; root.nudge = 0 } }
            function step(d) {
                const s = root.sel + d
                if (s >= visibleCount) {
                    if (root.page < pages - 1) { root.page++; root.sel = 0 }
                    else root.sel = visibleCount - 1
                } else if (s < 0) {
                    if (root.page > 0) { root.page--; root.sel = per - 1 }
                    else root.sel = 0
                } else root.sel = s
                root.hover = Wallpapers.get(root.page * per + root.sel)
            }
            function pickSelected() {
                const i = Math.max(0, root.sel)
                const info = Wallpapers.get(root.page * per + i)
                if (info.path) root.pick(info)
            }

            Item {
                anchors.fill: parent
                opacity: Math.max(0, Math.min(1, root.progress))

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: Config.data.wallpaper.dim * (1 - root.reveal * 0.9)
                }
                Image {
                    id: previewImg
                    anchors.fill: parent
                    visible: false
                    source: root.pickedUrl !== "" ? root.pickedUrl : root.lastPreview
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                MultiEffect {
                    anchors.fill: parent
                    source: previewImg
                    blurEnabled: true
                    blurMax: 64
                    blur: 1.0 - root.reveal * 0.97
                    opacity: root.pickedUrl !== "" ? root.reveal
                             : (Config.data.wallpaper.preview && root.hover ? 0.5 : 0)
                    Behavior on opacity { NumberAnimation { duration: 240 } }
                }
                Rectangle {                                    // tint with the dominant color of the hovered wallpaper
                    anchors.fill: parent
                    color: root.hover && root.hover.dominant ? root.hover.dominant : "transparent"
                    opacity: root.hover ? 0.16 : 0
                    Behavior on color { ColorAnimation { duration: 240 } }
                    Behavior on opacity { NumberAnimation { duration: 240 } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                    onWheel: (w) => win.scroll(w.angleDelta.y !== 0 ? w.angleDelta.y : w.angleDelta.x)
                }


                TextInput {
                    id: input
                    width: 1; height: 1; opacity: 0
                    onTextChanged: Wallpapers.query = text
                    Keys.onPressed: (e) => {
                        switch (e.key) {
                        case Qt.Key_Escape: root.back(); e.accepted = true; break
                        case Qt.Key_Right: case Qt.Key_Down: win.step(1); e.accepted = true; break
                        case Qt.Key_Left: case Qt.Key_Up: win.step(-1); e.accepted = true; break
                        case Qt.Key_Return: case Qt.Key_Enter: win.pickSelected(); e.accepted = true; break
                        case Qt.Key_Tab: root.cycleCategory(1); e.accepted = true; break
                        case Qt.Key_Backtab: root.cycleCategory(-1); e.accepted = true; break
                        case Qt.Key_PageDown: win.turn(-1); e.accepted = true; break
                        case Qt.Key_PageUp: win.turn(1); e.accepted = true; break
                        }
                    }
                }
                Connections {
                    target: root
                    function onOpenChanged() { if (root.open) { input.text = ""; input.forceActiveFocus() } }
                }
                Connections {
                    target: Wallpapers
                    function onQueryChanged() { if (input.text !== Wallpapers.query) input.text = Wallpapers.query }
                }

                WheelHandler {
                    onWheel: (e) => win.turn(e.angleDelta.y !== 0 ? e.angleDelta.y : e.angleDelta.x)
                }

                Rectangle {
                    x: root.cursorX - width / 2
                    y: root.cursorY - height / 2
                    width: Math.min(260, label.implicitWidth + 32)
                    height: 34
                    radius: 17
                    color: Theme.surfaceContainerHigh
                    scale: Math.max(0, root.progress) * (1 - root.reveal)
                    opacity: Math.min(1, root.progress)

                    Text {
                        id: label
                        anchors.centerIn: parent
                        width: parent.width - 24
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.hover ? root.hover.name : (Wallpapers.count === 0 ? "Nothing found" : "Pick a wallpaper")
                        color: Theme.onSurface
                        font.family: Config.data.appearance.font
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }

                Repeater {
                    model: Math.min(win.slots.length, win.per,
                                    Math.max(0, Wallpapers.count - root.shownPage * win.per))

                    delegate: Item {
                        id: cell
                        required property int index

                        readonly property int idx: root.shownPage * win.per + index
                        readonly property var slot: win.slots[index]
                        readonly property var info: {
                            Wallpapers.revision                      // thumbnails and favorites arrive later
                            return Wallpapers.count > idx ? Wallpapers.get(idx) : ({})
                        }

                        readonly property real p: Math.max(0, Math.min(1.25, root.progress * root.swap * 1.5 - index * 0.025))
                                                  * (1 - root.reveal)
                        readonly property real ang: root.spin * (1 - root.swap) * 0.7 + root.nudge * 0.3
                        readonly property real dx: slot.x - root.cursorX
                        readonly property real dy: slot.y - root.cursorY

                        width: root.tileW
                        height: root.tileH
                        x: root.cursorX + (dx * Math.cos(ang) - dy * Math.sin(ang)) * p - width / 2
                        y: root.cursorY + (dx * Math.sin(ang) + dy * Math.cos(ang)) * p - height / 2
                        scale: 0.3 + 0.7 * Math.min(1, p)
                        opacity: Math.min(1, p * 1.5)
                        z: tile.active ? 10 : 0

                        WallpaperTile {
                            id: tile
                            anchors.fill: parent
                            info: cell.info
                            shaped: root.shaped
                            current: (cell.info.path ?? "") === Wallpapers.current
                            active: root.sel === cell.index

                            onEntered: { root.sel = cell.index; root.hover = cell.info }
                            onExited: { if (root.hover && root.hover.path === cell.info.path) root.hover = null }
                            onClicked: root.pick(cell.info)
                            onScrolled: (d) => win.scroll(d)
                        }
                    }
                }

                WallpaperBar {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 36
                    pages: win.pages
                    page: root.page
                    scale: Math.max(0, Math.min(1, root.progress))
                    opacity: Math.min(1, root.progress) * (1 - root.reveal)
                }
            }
        }
    }
}