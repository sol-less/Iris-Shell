import Iris
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    property int tileW: 150
    property int tileH: 84

    property bool open: false
    property string monitor: ""
    property real cursorX: 0
    property real cursorY: 0
    property int page: 0
    property string hovered: ""
    property int perPage: 7

    property int shownPage: 0       // the page whose tiles are on screen
    property real swap: 1           // 1 = tiles out, 0 = folded into the cursor
    property int dir: 1             // +1 next page, -1 previous page
    property real spin: 0           // rotation direction during the swap

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

    property real progress: open ? 1 : 0
    Behavior on progress { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

    function toggle() {
        if (open) { open = false; return }
        const c = Wallpapers.cursor()
        if (!c.ok) return               // not running under Hyprland
        monitor = c.monitor
        cursorX = c.x
        cursorY = c.y
        page = 0
        hovered = ""
        open = true
        swapAnim.stop()
        swap = 1
        shownPage = 0
        page = 0
    }

    function pick(path) {
        open = false
        Wallpapers.apply(path)
    }

    function easeOutBack(t) {
        const c1 = 1.2, c3 = c1 + 1
        return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2)
    }

    // qs ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.toggle(); }
        function close(): void { root.open = false; }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            visible: root.progress > 0 && modelData.name === root.monitor
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "iris-wallpaper"
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors { top: true; bottom: true; left: true; right: true }

            property var slots: Wallpapers.ringSlots(root.cursorX, root.cursorY, width, height, root.tileW, root.tileH)
            readonly property int perPage: Math.max(1, Math.min(root.perPage, slots.length))
            readonly property int pages: Math.max(1, Math.ceil(Wallpapers.count / perPage))

            function turn(d) {
                if (cooldown.running) return
                root.page = Math.max(0, Math.min(pages - 1, root.page + (d < 0 ? 1 : -1)))
                cooldown.restart()
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.open = false

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.4 * root.progress
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                    onWheel: (wheel) => win.turn(wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x)
                }

                Timer { id: cooldown; interval: 220 }
                WheelHandler {
                    onWheel: (e) => {
                        if (cooldown.running) return
                        const d = e.angleDelta.y !== 0 ? e.angleDelta.y : e.angleDelta.x
                        root.page = Math.max(0, Math.min(win.pages - 1, root.page + (d < 0 ? 1 : -1)))
                        cooldown.restart()
                    }
                }

                // label at the cursor
                Rectangle {
                    x: root.cursorX - width / 2
                    y: root.cursorY - height / 2
                    width: label.implicitWidth + 24
                    height: 30
                    radius: 15
                    color: Theme.surface
                    scale: root.progress
                    opacity: root.progress

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: root.hovered !== "" ? root.hovered : (root.page + 1) + " / " + win.pages
                        color: Theme.onSurface
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }

                Repeater {
                    model: Math.min(win.slots.length, win.perPage, Math.max(0, Wallpapers.count - root.shownPage * win.perPage))

                    delegate: Item {
                        id: tile
                        required property int index

                        readonly property int idx: root.shownPage * win.perPage + index

                        readonly property real p: root.easeOutBack(
                            Math.max(0, Math.min(1, root.progress * root.swap * 1.5 - index * 0.025)))

                        readonly property real ang: root.spin * (1 - root.swap) * 0.7
                        readonly property real dx: slot.x - root.cursorX
                        readonly property real dy: slot.y - root.cursorY

                        x: root.cursorX + (dx * Math.cos(ang) - dy * Math.sin(ang)) * p - width / 2
                        y: root.cursorY + (dx * Math.sin(ang) + dy * Math.cos(ang)) * p - height / 2
                        readonly property var slot: win.slots[index]
                        readonly property var info: Wallpapers.count > idx ? Wallpapers.get(idx) : ({})

                        property real hoverScale: mouse.containsMouse ? 1.12 : 1
                        Behavior on hoverScale { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }

                        width: root.tileW
                        height: root.tileH
                        scale: (0.3 + 0.7 * Math.min(1, p)) * hoverScale
                        opacity: Math.min(1, p * 1.5)
                        z: mouse.containsMouse ? 10 : 0

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: 14
                            color: Theme.surfaceContainer
                            border.width: mouse.containsMouse ? 2 : 0
                            border.color: Theme.primary

                            Image {
                                anchors.fill: parent
                                source: tile.info.url ?? ""
                                sourceSize.width: 320
                                sourceSize.height: 180
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.hovered = tile.info.name ?? ""
                            onExited: if (root.hovered === tile.info.name) root.hovered = ""
                            onClicked: root.pick(tile.info.path)
                            onWheel: (wheel) => win.turn(wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x)
                        }
                    }
                }
            }
        }
    }
}