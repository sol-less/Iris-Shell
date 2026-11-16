import QtQuick
import Quickshell
import Quickshell.Widgets
import M3Shapes
import Iris

Item {
    id: root
    signal launched()
    property string hovered: ""

    function src(icon) {
        return icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon, "application-x-executable")
    }

    Text {
        id: label
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 14
        text: root.hovered !== "" ? root.hovered : "Apps"
        color: root.hovered !== "" ? Theme.onSurface : Theme.onSurfaceVariant
        font.family: Config.data.appearance.font
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }

    GridView {
        anchors.top: label.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        cellWidth: 60
        cellHeight: 60
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Applications

        delegate: Item {
            id: cell
            required property int index
            required property string name
            required property string icon
            required property string appId
            width: 60; height: 60

            MaterialShape {
                anchors.centerIn: parent
                implicitSize: 50
                shape: mouse.containsMouse ? MaterialShape.Cookie6Sided : MaterialShape.Circle
                color: Theme.surfaceContainerHighest
                opacity: mouse.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }
            }
            IconImage {
                anchors.centerIn: parent
                implicitSize: 30
                source: root.src(cell.icon)
                scale: mouse.pressed ? 0.85 : (mouse.containsMouse ? 1.15 : 1)
                Behavior on scale { Spring {} }
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hovered = cell.name
                onExited: if (root.hovered === cell.name) root.hovered = ""
                onClicked: { Applications.launchById(cell.appId); root.launched() }
            }
        }
    }
}