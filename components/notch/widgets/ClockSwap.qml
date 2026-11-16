import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Iris

Item {
    id: root

    property bool swapped: false                     // a workspace switch just happened
    property int lastId: -1
    property int dir: 1                              // +1: the workspaces come up from below, -1: from above
    readonly property bool showWs: swapped || hover.hovered

    Layout.fillHeight: true
    implicitHeight: 36
    clip: true

    property real mix: showWs ? 1 : 0
    Behavior on mix { Spring {} }

    implicitWidth: Math.max(1, Motion.lerp(clock.implicitWidth, ws.implicitWidth, mix))

    Clock {
        id: clock
        x: (root.width - width) / 2
        y: (root.height - height) / 2 - root.dir * root.mix * root.height * 0.85
        opacity: 1 - Motion.clamp01(root.mix * 1.4)
    }
    Workspace {
        id: ws
        x: (root.width - width) / 2
        y: (root.height - height) / 2 + root.dir * (1 - root.mix) * root.height * 0.85
        opacity: Motion.clamp01(root.mix * 1.4 - 0.2)
        enabled: root.mix > 0.5
    }

    HoverHandler { id: hover }                       // hovering shows the workspaces so you can click them

    Timer { id: hold; interval: Config.data.notch.workspaceHoldMs; onTriggered: root.swapped = false }

    Component.onCompleted: lastId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "workspace" && event.name !== "workspacev2") return
            const id = parseInt(String(event.data).split(",")[0])
            if (isNaN(id)) return
            if (root.lastId > 0) root.dir = id >= root.lastId ? 1 : -1
            root.lastId = id
            root.swapped = true
            hold.restart()
        }
    }
}