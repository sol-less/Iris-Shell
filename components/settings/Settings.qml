import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Iris

Scope {
    id: root

    property bool open: false
    property rect pillRect: Qt.rect(0, 0, 190, 36)
    property real pillRadius: 18
    property var theme: null

    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: root.open ? Motion.slow * 1.5 : Motion.slow * 1.25
            easing.type: Easing.Linear
        }
    }

    readonly property bool shown: open || progress > 0.001

    onOpenChanged: if (open) Qt.callLater(() => stage.forceActiveFocus())

    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
    }

    PanelWindow {
        id: win

        readonly property real baseW: 1100
        readonly property real baseH: 680
        readonly property real fit: Math.max(0.4, Math.min(1, (width - 64) / baseW, (height - 168) / baseH))

        function ease(x) {
            const k = Math.max(0, Math.min(1, x))
            return k * k * (3 - 2 * k)
        }
        function mix(a, b, k) {
            return Qt.rgba(a.r + (b.r - a.r) * k, a.g + (b.g - a.g) * k, a.b + (b.b - a.b) * k, a.a + (b.a - a.a) * k)
        }

        readonly property real t: ease(root.progress / 0.7)
        readonly property real m: ease((root.progress - 0.15) / 0.85)
        readonly property real c: ease((root.progress - 0.55) / 0.4)
        readonly property real pcx: root.pillRect.x + root.pillRect.width / 2
        readonly property real pcy: root.pillRect.y + root.pillRect.height / 2

        visible: root.shown
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "iris-settings"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        MouseArea {
            anchors.fill: parent
            enabled: root.open
            onClicked: root.open = false
        }

        ClippingRectangle {
            id: panel
            width: Motion.lerp(root.pillRect.width, win.baseW * win.fit, win.m)
            height: Motion.lerp(root.pillRect.height, win.baseH * win.fit, win.m)
            x: Motion.lerp(win.pcx, win.width / 2, win.t) - width / 2
            y: Motion.lerp(win.pcy, win.height / 2, win.t) - height / 2
            radius: Motion.lerp(root.pillRadius, 44, win.m)
            color: win.mix(Theme.surfaceContainerHigh, Theme.surface, win.m)

            MouseArea { anchors.fill: parent }

            SettingsStage {
                id: stage
                anchors.centerIn: parent
                width: win.baseW
                height: win.baseH
                scale: win.fit * (0.94 + 0.06 * win.c)
                visible: win.c > 0.01
                opacity: win.c
                active: root.shown && win.c > 0.01
                theme: root.theme
                onCloseRequested: root.open = false
            }
        }
    }
}