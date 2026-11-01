import Iris
import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    signal launched(string appId)

    property int iconSize: 22
    property int spacing: 8
    property real maxStripWidth: 300      // the strip scrolls beyond this
    property string hovered: ""           // name of the app under the mouse
    readonly property string fontFamily: "Inter"

    function iconSrc(icon) {
        if (icon.startsWith("/")) return "file://" + icon
        return Quickshell.iconPath(icon, "application-x-executable")
    }

    implicitWidth: list.width + 10 + label.width
    implicitHeight: 36

    // ----- the icon strip -----
    ListView {
        id: list
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        width: Math.min(root.maxStripWidth, contentWidth + leftMargin + rightMargin)
        height: root.iconSize + 12        // room for the hover scale
        orientation: ListView.Horizontal
        spacing: root.spacing
        leftMargin: 4                     // keeps the scaled first and last icons from being clipped
        rightMargin: 4
        clip: true
        interactive: false                // the pill's swipe uses dragging; we scroll with the wheel instead

        model: Applications

        Behavior on contentX {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id: entry

            required property int index
            required property string name
            required property string icon
            required property string appId

            width: root.iconSize
            height: list.height

            IconImage {
                anchors.centerIn: parent
                implicitSize: root.iconSize
                source: root.iconSrc(entry.icon)
                scale: mouse.containsMouse ? 1.25 : 1

                Behavior on scale {
                    NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onEntered: root.hovered = entry.name
                onExited: if (root.hovered === entry.name) root.hovered = ""
                onClicked: {
                    Applications.launchById(entry.appId)
                    root.launched(entry.appId)
                }
            }
        }
    }

    // ----- name of the hovered app -----
    Text {
        id: label
        anchors.left: list.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 110

        text: root.hovered !== "" ? root.hovered : "Apps"
        color: root.hovered !== "" ? Theme.onSurface : Theme.onSurfaceVariant
        font.family: root.fontFamily
        font.pixelSize: 12
        font.weight: Font.Medium
        elide: Text.ElideRight

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ----- scroll the strip with the mouse wheel or a two-finger swipe -----
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (e) => {
            const d = e.angleDelta.x !== 0 ? e.angleDelta.x : e.angleDelta.y
            const minX = -list.leftMargin
            const maxX = list.contentWidth + list.rightMargin - list.width
            list.contentX = Math.max(minX, Math.min(maxX, list.contentX - d * 0.6))
        }
    }
}