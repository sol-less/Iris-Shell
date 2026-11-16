import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import Quickshell.Widgets
import Iris

Scope {
    id: root

    property bool open: false
    property bool editing: false
    property int page: 0
    property int shownPage: 0
    property int dir: 1
    property real enter: 0
    property real slide: 0
    property real boardAlpha: 1
    property var dragOrder: null
    property string dragUid: ""
    property var resizeSpec: null
    property var resizeBase: null
    signal openSettings()

    readonly property var cfg: Config.data.deck
    readonly property var pages: cfg.pages
    readonly property var current: pages[Math.min(shownPage, pages.length - 1)] ?? ({ id: "none", widgets: [] })
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property string fontFamily: Config.data.appearance.font
    readonly property int cols: 12
    property bool blocked: false

    property real progress: open ? 1 : 0
    Behavior on progress { Spring {} }

    NumberAnimation { id: enterAnim; target: root; property: "enter"; from: 0; to: 1; duration: 1000; easing.type: Easing.OutCubic }


    onBlockedChanged: if (blocked) { open = false; editing = false }
    onOpenChanged: {
        if (open && blocked) { open = false; return }
        if (open) { Hud.markRead(); enterAnim.restart() }
        else editing = false
    }
    onEditingChanged: {
        if (editing) ensureUids()
        else { dragOrder = null; dragUid = ""; resizeSpec = null; resizeBase = null }
    }
    onPagesChanged: if (editing) ensureUids()

    Binding { target: SystemStats; property: "enabled"; value: root.open }
    PwObjectTracker { objects: [root.sink, Pipewire.defaultAudioSource] }

    Component { id: clockC; ClockHero { color: "transparent" } }
    Component { id: togglesC; TogglesWidget {} }
    Component { id: mediaC; MediaCard { color: "transparent"; active: root.open } }
    Component { id: slidersC; SlidersCard { color: "transparent"; sink: root.sink } }
    Component { id: calendarC; CalendarCard { color: "transparent" } }
    Component { id: timerC; TimerCard { color: "transparent"; active: root.open } }
    Component { id: notificationsC; NotificationsWidget {} }
    Component { id: statsC; StatsWidget {} }
    Component { id: appsC; AppsWidget { onLaunched: if (root.cfg.closeOnLaunch) root.open = false } }
    Component { id: scenesC; ScenesWidget { scenes: root.cfg.scenes; onRun: (s) => root.runScene(s) } }
    Component { id: noteC; NoteWidget {} }
    Component { id: powerC; PowerWidget { onLocking: root.open = false } }

    readonly property var builtin: ({
        clock:         { name: "Clock",          w: 4, h: 2, tone: "tertiaryContainer",    comp: clockC },
        toggles:       { name: "Quick toggles",  w: 4, h: 3, tone: "surfaceContainer",     comp: togglesC },
        media:         { name: "Now playing",    w: 4, h: 3, tone: "secondaryContainer",   comp: mediaC },
        sliders:       { name: "Volume",         w: 4, h: 2, tone: "surfaceContainerHigh", comp: slidersC },
        calendar:      { name: "Calendar",       w: 4, h: 5, tone: "surfaceContainerHigh", comp: calendarC },
        timer:         { name: "Timer",          w: 4, h: 2, tone: "surfaceContainerHigh", comp: timerC },
        notifications: { name: "Notifications",  w: 8, h: 3, tone: "surfaceContainer",     comp: notificationsC },
        stats:         { name: "System",         w: 4, h: 2, tone: "surfaceContainerHigh", comp: statsC },
        apps:          { name: "Apps",           w: 4, h: 3, tone: "surfaceContainer",     comp: appsC },
        scenes:        { name: "Scenes",         w: 4, h: 1, tone: "surfaceContainerHigh", comp: scenesC },
        note:          { name: "Note",           w: 4, h: 2, tone: "surfaceContainerHigh", comp: noteC },
        power:         { name: "Power",          w: 4, h: 1, tone: "surfaceContainer",     comp: powerC }
    })

    FolderListModel {
        id: userFiles
        folder: "file://" + Quickshell.shellDir + "/custom"
        nameFilters: ["*.qml"]
        showDirs: false
    }
    readonly property var userWidgets: {
        const out = {}
        for (let i = 0; i < userFiles.count; i++) {
            const n = String(userFiles.get(i, "fileName")).replace(/\.qml$/, "")
            out["user:" + n] = { name: n + " (yours)", w: 4, h: 2, tone: "surfaceContainerHigh",
                                 url: userFiles.get(i, "fileUrl") }
        }
        return out
    }
    readonly property var catalog: Object.assign({}, builtin, userWidgets)

    readonly property real pad: 24
    readonly property real gap: cfg.gap
    readonly property real innerW: cfg.width - 2 * pad
    readonly property real colW: (innerW - (cols - 1) * gap) / cols

    function uidOf(p, w, i) { return w.uid ?? (p.id + ":" + i + ":" + w.type) }

    function layoutItems(widgets) {
        const occ = []
        const out = []
        widgets.forEach((spec, index) => {
            const w = Math.min(cols, Math.max(1, spec.w)), h = Math.max(1, spec.h)
            let placed = false
            for (let r = 0; !placed; r++) {
                for (let c = 0; c + w <= cols && !placed; c++) {
                    let free = true
                    for (let y = r; y < r + h && free; y++)
                        for (let x = c; x < c + w; x++)
                            if (occ[y] && occ[y][x]) { free = false; break }
                    if (!free) continue
                    for (let y = r; y < r + h; y++) {
                        occ[y] = occ[y] || []
                        for (let x = c; x < c + w; x++) occ[y][x] = true
                    }
                    out.push({ uid: spec.uid, index: index, spec: spec, c: c, r: r, w: w, h: h })
                    placed = true
                }
            }
        })
        return out
    }

    readonly property var baseWidgets: {
        const p = current
        return (p.widgets ?? []).map((w, i) => Object.assign({}, w, { uid: uidOf(p, w, i) }))
    }
    readonly property var liveWidgets: {
        let list = baseWidgets
        if (resizeSpec)
            list = list.map(w => w.uid === resizeSpec.uid ? Object.assign({}, w, { w: resizeSpec.w, h: resizeSpec.h }) : w)
        if (dragOrder) {
            const byId = {}
            list.forEach(w => { byId[w.uid] = w })
            const next = dragOrder.filter(id => byId[id]).map(id => byId[id])
            list.forEach(w => { if (!dragOrder.includes(w.uid)) next.push(w) })
            list = next
        }
        return list
    }
    readonly property var items: layoutItems(liveWidgets)
    readonly property var byUid: { const m = {}; for (const it of items) m[it.uid] = it; return m }
    readonly property int rows: items.reduce((m, it) => Math.max(m, it.r + it.h), 1)
    readonly property real contentH: rows * cfg.unit + (rows - 1) * gap

    ListModel { id: cardModel }
    function syncCards() {
        const want = items.map(it => it.uid)
        for (let i = cardModel.count - 1; i >= 0; i--)
            if (!want.includes(cardModel.get(i).uid)) cardModel.remove(i)
        const have = []
        for (let i = 0; i < cardModel.count; i++) have.push(cardModel.get(i).uid)
        for (const uid of want) if (!have.includes(uid)) cardModel.append({ uid: uid })
    }
    onItemsChanged: if (!swapAnim.running) syncCards()
    Component.onCompleted: syncCards()

    function rebuild() {
        cardModel.clear()
        syncCards()
        enter = 0
        enterAnim.restart()
    }
    onPageChanged: {
        if (page === shownPage) return
        dir = page > shownPage ? 1 : -1
        dragOrder = null
        dragUid = ""
        resizeSpec = null
        if (cfg.pageSlide) swapAnim.restart()
        else { shownPage = page; rebuild() }
    }
    SequentialAnimation {
        id: swapAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "slide"; to: -root.dir; duration: 140; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "boardAlpha"; to: 0; duration: 140 }
        }
        ScriptAction { script: { root.shownPage = root.page; root.rebuild(); root.slide = root.dir } }
        ParallelAnimation {
            NumberAnimation { target: root; property: "slide"; to: 0; duration: 420; easing.type: Easing.OutBack }
            NumberAnimation { target: root; property: "boardAlpha"; to: 1; duration: 200 }
        }
    }

    function ensureUids() {
        const all = JSON.parse(JSON.stringify(root.pages))
        let dirty = false
        all.forEach(p => p.widgets.forEach((w, k) => {
            if (!w.uid) { w.uid = uidOf(p, w, k); dirty = true }
        }))
        if (dirty) Config.set("deck.pages", all)
    }

    function mutate(fn) {
        const all = JSON.parse(JSON.stringify(root.pages))
        const p = all[Math.min(root.shownPage, all.length - 1)]
        if (p) {
            p.widgets.forEach((w, k) => { if (!w.uid) w.uid = uidOf(p, w, k) })
            fn(p, all)
        }
        Config.set("deck.pages", all)
    }

    function previewDrag(uid, cx, cy) {
        const me = baseWidgets.find(w => w.uid === uid)
        if (!me) return
        const rest = baseWidgets.filter(w => w.uid !== uid)
        let best = 0
        let bestD = Infinity
        for (let i = 0; i <= rest.length; i++) {
            const trial = rest.slice(0, i).concat([me], rest.slice(i))
            const at = layoutItems(trial).find(it => it.uid === uid)
            const px = at.c * (colW + gap) + (at.w * colW + (at.w - 1) * gap) / 2
            const py = at.r * (cfg.unit + gap) + (at.h * cfg.unit + (at.h - 1) * gap) / 2
            const d = (px - cx) * (px - cx) + (py - cy) * (py - cy)
            if (d < bestD) { bestD = d; best = i }
        }
        const order = rest.slice(0, best).concat([me], rest.slice(best)).map(w => w.uid)
        if (!dragOrder || dragOrder.join("|") !== order.join("|")) dragOrder = order
    }

    function commitDrag() {
        const order = dragOrder
        if (order) {
            mutate(p => {
                const byId = {}
                p.widgets.forEach(w => { byId[w.uid] = w })
                const next = order.map(id => byId[id]).filter(w => w)
                p.widgets.forEach(w => { if (!order.includes(w.uid)) next.push(w) })
                p.widgets = next
            })
        }
        dragOrder = null
        dragUid = ""
    }

    function beginResize(uid) {
        const it = byUid[uid]
        if (!it) return
        resizeBase = {
            uid: uid,
            pw: it.w * colW + (it.w - 1) * gap,
            ph: it.h * cfg.unit + (it.h - 1) * gap
        }
    }

    function moveResize(dx, dy) {
        if (!resizeBase) return
        const w = Math.max(1, Math.min(cols, Math.round((resizeBase.pw + dx + gap) / (colW + gap))))
        const h = Math.max(1, Math.min(10, Math.round((resizeBase.ph + dy + gap) / (cfg.unit + gap))))
        if (!resizeSpec || resizeSpec.w !== w || resizeSpec.h !== h)
            resizeSpec = { uid: resizeBase.uid, w: w, h: h }
    }

    function commitResize() {
        const s = resizeSpec
        if (s) {
            mutate(p => {
                const w = p.widgets.find(x => x.uid === s.uid)
                if (w) { w.w = s.w; w.h = s.h }
            })
        }
        resizeSpec = null
        resizeBase = null
    }

    function addWidget(type) {
        const d = catalog[type]
        const uid = type + "-" + Date.now().toString(36) + Math.floor(Math.random() * 1000)
        mutate(p => p.widgets.push({ uid: uid, type: type, w: d.w, h: d.h }))
    }
    function addPage() {
        mutate((p, all) => all.push({ id: "p" + Date.now(), name: "Page " + (all.length + 1), widgets: [] }))
        Qt.callLater(() => { root.page = root.pages.length - 1 })
    }
    function deletePage() {
        if (pages.length <= 1) return
        const i = shownPage
        mutate((p, all) => all.splice(i, 1))
        page = Math.max(0, i - 1)
        shownPage = page
        rebuild()
    }

    function runScene(s) {
        if (s.dnd !== undefined && s.dnd !== Hud.dnd) Hud.toggleDnd()
        if (s.caffeine !== undefined) Hud.caffeine = s.caffeine
        if (s.volume !== undefined && sink && sink.audio) sink.audio.volume = s.volume / 100
        if (s.timer) Countdown.start(s.timer, s.name)
        else if (s.timer === 0) Countdown.cancel()
        Hud.showToast(s.name)
    }

    function renamePage(i, raw) {
        const name = raw.trim().slice(0, 24)
        if (name === "") return
        const all = JSON.parse(JSON.stringify(root.pages))
        if (!all[i]) return
        all[i].name = name
        Config.set("deck.pages", all)
    }

    IpcHandler {
        target: "deck"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
        function page(n: int): void { root.page = Math.max(0, n - 1); root.open = true }
        function edit(): void { if (root.blocked) return; root.open = true; root.editing = !root.editing }
    }
    IpcHandler {
        target: "panel"
        function toggle(): void { root.open = !root.open }
        function close(): void { root.open = false }
    }

    PanelWindow {
        visible: root.progress > 0.001
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "iris-deck"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        Item {
            id: stage
            anchors.fill: parent
            focus: true
            onVisibleChanged: if (visible) forceActiveFocus()

            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_Escape) { if (root.editing) root.editing = false; else root.open = false }
                else if (e.key === Qt.Key_Left) root.page = Math.max(0, root.page - 1)
                else if (e.key === Qt.Key_Right) root.page = Math.min(root.pages.length - 1, root.page + 1)
                else if (e.key === Qt.Key_E) root.editing = !root.editing
                else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) root.page = Math.min(root.pages.length - 1, e.key - Qt.Key_1)
                else return
                e.accepted = true
            }

            MouseArea { anchors.fill: parent; onClicked: root.open = false }

            ClippingRectangle {
                id: panel

                readonly property real fullW: root.cfg.width
                readonly property real fullH: body.implicitHeight + 48
                readonly property real fit: Math.max(0.45, Math.min(1, (stage.width - 32) / fullW, (stage.height - 84) / fullH))
                readonly property real w: fullW * fit
                readonly property real h: fullH * fit
                readonly property string pos: root.cfg.position
                readonly property bool bloom: root.cfg.bloom
                readonly property real p: Math.max(0, root.progress)
                readonly property real t: bloom ? p : Math.min(1, p)

                readonly property real ox: pos === "notch" ? stage.width / 2 - 95 : (pos === "right" ? stage.width - 76 : stage.width / 2 - 32)
                readonly property real oy: pos === "notch" ? 8 : (pos === "right" ? 62 : stage.height / 2 - 32)
                readonly property real ow: pos === "notch" ? 190 : (pos === "right" ? 56 : 64)
                readonly property real oh: pos === "notch" ? 36 : (pos === "right" ? 56 : 64)
                readonly property real fx: pos === "right" ? stage.width - 20 - w : (stage.width - w) / 2
                readonly property real fy: pos === "center" ? (stage.height - h) / 2 : 62

                x: Motion.lerp(bloom ? ox : fx, fx, t)
                y: Motion.lerp(bloom ? oy : fy - 30, fy, t)
                width: bloom ? Math.max(ow * 0.5, Motion.lerp(ow, w, t)) : w
                height: bloom ? Math.max(oh * 0.5, Motion.lerp(oh, h, t)) : h
                radius: bloom ? Motion.lerp(18, root.cfg.radius + 10, Math.min(1, t)) : root.cfg.radius + 10
                opacity: bloom ? Math.min(1, p * 4) : Math.max(0, Math.min(1, p))
                scale: bloom ? 1 : 0.94 + 0.06 * Math.min(1, p)
                color: root.cfg.style === "glass" ? Qt.alpha(Theme.surface, 0.55 * root.cfg.cardOpacity + 0.25) : Theme.surface

                MouseArea { anchors.fill: parent }

                Item {
                    id: inner
                    width: panel.fullW
                    height: panel.fullH
                    x: (panel.width - width) / 2
                    y: 0
                    transformOrigin: Item.Top
                    scale: panel.fit
                    opacity: panel.bloom ? Motion.clamp01(panel.p * 1.9 - 0.6) : 1

                    ColumnLayout {
                        id: body
                        x: root.pad
                        y: root.pad
                        width: root.innerW
                        spacing: 14

                        DeckHeader {
                            Layout.fillWidth: true
                            pages: root.pages
                            page: root.page
                            editing: root.editing
                            active: root.open
                            onRenameRequested: (i, n) => root.renamePage(i, n)
                            onPageRequested: (i) => root.page = i
                            onEditToggled: root.editing = !root.editing
                            onSettingsRequested: { root.open = false; root.openSettings() }
                            onAddPageRequested: root.addPage()
                            onDeletePageRequested: root.deletePage()
                            onResetRequested: Config.reset("deck.pages")
                        }

                        Flow {
                            id: palette
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.editing ? implicitHeight : 0
                            clip: true
                            opacity: root.editing ? 1 : 0
                            spacing: 6
                            Behavior on Layout.preferredHeight { Spring {} }
                            Behavior on opacity { NumberAnimation { duration: 160 } }

                            Text {
                                text: "Add:"
                                height: 34
                                verticalAlignment: Text.AlignVCenter
                                color: Theme.onSurfaceVariant
                                font.family: root.fontFamily
                                font.pixelSize: 12
                            }
                            Repeater {
                                model: Object.keys(root.catalog)
                                delegate: Chip {
                                    required property string modelData
                                    text: root.catalog[modelData].name
                                    onClicked: root.addWidget(modelData)
                                }
                            }
                        }

                        Item {
                            id: board
                            Layout.preferredWidth: root.innerW
                            Layout.preferredHeight: root.contentH
                            Behavior on Layout.preferredHeight { Spring {} }
                            opacity: root.boardAlpha
                            transform: Translate { x: root.slide * 60 }

                            Text {
                                visible: root.items.length === 0
                                anchors.centerIn: parent
                                text: root.editing ? "Add a widget from the list above" : "This page is empty. Press E to edit it"
                                color: Theme.onSurfaceVariant
                                font.family: root.fontFamily
                                font.pixelSize: 15
                            }

                            Rectangle {
                                readonly property var it: root.dragUid !== "" ? root.byUid[root.dragUid] : undefined
                                visible: it !== undefined
                                z: -1
                                radius: root.cfg.radius
                                color: Qt.alpha(Theme.primary, 0.16)
                                border.width: 2
                                border.color: Qt.alpha(Theme.primary, 0.5)
                                x: it ? it.c * (root.colW + root.gap) : 0
                                y: it ? it.r * (root.cfg.unit + root.gap) : 0
                                width: it ? it.w * root.colW + (it.w - 1) * root.gap : 0
                                height: it ? it.h * root.cfg.unit + (it.h - 1) * root.gap : 0
                                Behavior on x { Spring {} }
                                Behavior on y { Spring {} }
                                Behavior on width { Spring {} }
                                Behavior on height { Spring {} }
                            }

                            Repeater {
                                model: cardModel
                                delegate: DeckCard {
                                    id: card
                                    required property string uid
                                    readonly property var it: root.byUid[uid]

                                    visible: it !== undefined
                                    def: it ? (root.catalog[it.spec.type] ?? ({ name: it.spec.type, tone: "surfaceContainerHigh" })) : ({})
                                    content: def.comp ?? null
                                    contentUrl: def.url ?? ""
                                    editing: root.editing
                                    uiScale: panel.fit
                                    badge: root.resizeSpec && root.resizeSpec.uid === uid ? root.resizeSpec.w + "×" + root.resizeSpec.h : ""

                                    order: it ? it.r * 2 + it.c / 3 : 0
                                    reveal: Motion.back(Motion.stagger(root.enter, order, root.cfg.stagger))
                                    fresh: root.enter >= 0.999

                                    slotX: it ? it.c * (root.colW + root.gap) : 0
                                    slotY: it ? it.r * (root.cfg.unit + root.gap) : 0
                                    width: it ? it.w * root.colW + (it.w - 1) * root.gap : 0
                                    height: it ? it.h * root.cfg.unit + (it.h - 1) * root.gap : 0

                                    onRemove: root.mutate(p => {
                                        const k = p.widgets.findIndex(w => w.uid === card.uid)
                                        if (k >= 0) p.widgets.splice(k, 1)
                                    })
                                    onDragStarted: root.dragUid = card.uid
                                    onDragMoved: (cx, cy) => root.previewDrag(card.uid, cx, cy)
                                    onDragEnded: root.commitDrag()
                                    onResizeStarted: root.beginResize(card.uid)
                                    onResizeMoved: (dx, dy) => root.moveResize(dx, dy)
                                    onResizeEnded: root.commitResize()
                                }
                            }
                        }
                    }
                }
            }

            MultiEffect {
                visible: root.cfg.shadow
                z: -1
                source: panel
                x: panel.x; y: panel.y
                width: panel.width; height: panel.height
                opacity: panel.opacity
                shadowEnabled: true
                shadowColor: "#000000"
                shadowBlur: 0.9
                shadowOpacity: 0.45
                shadowVerticalOffset: 6
            }
        }
    }
}