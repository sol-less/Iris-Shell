import QtQuick
import QtQuick.Layouts
import Quickshell
import Iris

Item {
    id: root
    signal locking()

    Flow {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 12
        spacing: 6

        PowerChip { u: 0.82; text: "Lock"; onActivated: { root.locking(); Quickshell.execDetached(["qs", "ipc", "call", "lock", "lock"]) } }
        PowerChip { u: 0.82; text: "Sleep"; onActivated: Quickshell.execDetached(["systemctl", "suspend"]) }
        PowerChip { u: 0.82; text: "Restart"; confirm: true; onActivated: Quickshell.execDetached(["systemctl", "reboot"]) }
        PowerChip { u: 0.82; text: "Shut down"; confirm: true; onActivated: Quickshell.execDetached(["systemctl", "poweroff"]) }
    }
}