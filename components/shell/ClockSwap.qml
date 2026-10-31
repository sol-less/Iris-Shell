import "."
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Item {
    id: root

    property bool showWorkspaces: false
    property int holdMs: 1500

    function sizeOf(item) {
        return Math.max(item.implicitWidth, item.childrenRect.width, item.width, 1);
    }

    Layout.fillHeight: true
    implicitHeight: 36
    implicitWidth: showWorkspaces ? sizeOf(workspaces) : sizeOf(clock)
    clip: true
    Component.onCompleted: console.log("switcher sizes: clock", clock.implicitWidth, clock.width, "workspaces", workspaces.implicitWidth, workspaces.width, "heights", clock.height, workspaces.height)

    Connections {
        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "workspacev2") {
                console.log("switcher: workspace event", event.name, event.data);
                root.showWorkspaces = true;
                hideTimer.restart();
            }
        }

        target: Hyprland
    }

    Timer {
        id: hideTimer

        interval: root.holdMs
        onTriggered: root.showWorkspaces = false
    }

    Clock {
        id: clock

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.showWorkspaces ? -height : (root.height - height) / 2
        opacity: root.showWorkspaces ? 0 : 1

        Behavior on y {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }

        }

    }

    Workspace {
        id: workspaces

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.showWorkspaces ? (root.height - height) / 2 : root.height
        opacity: root.showWorkspaces ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }

        }

    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }

    }

}
