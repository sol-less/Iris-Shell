import QtQuick
import Quickshell
import Quickshell.Hyprland
import Iris

Item {
    width: 100
    height: parent.height

    Text {
        id: textHandler
        text: "Workspace " + Hyprland.focusedWorkspace?.id
        anchors.centerIn: parent
        font.family: "Inter"
        font.pixelSize: 14
        font.weight: 600
        color: Theme.primary
    }
}