import QtQuick
import QtQuick.Layouts
import Quickshell
import Iris

ColumnLayout {
    id: root
    property var theme: null
    readonly property string fontFamily: Config.data.appearance.font
    readonly property string folder: Config.path.substring(0, Config.path.lastIndexOf("/"))
    property bool confirm: false
    spacing: 2

    Timer { id: confirmTimer; interval: 3000; onTriggered: root.confirm = false }

    component Cell: Rectangle {
        property bool first: false
        property bool last: false
        default property alias content: inner.data
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + 34
        topLeftRadius: first ? 28 : 8
        topRightRadius: first ? 28 : 8
        bottomLeftRadius: last ? 28 : 8
        bottomRightRadius: last ? 28 : 8
        color: Theme.surfaceContainer
        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: 22
            anchors.topMargin: 17
            anchors.bottomMargin: 17
            spacing: 4
        }
    }

    component TonalButton: Rectangle {
        property string text: ""
        property bool danger: false
        signal clicked()
        implicitWidth: lbl.implicitWidth + 36
        implicitHeight: 40
        radius: press.pressed ? 12 : 20
        color: danger ? Theme.errorContainer : Theme.secondaryContainer
        Behavior on radius { SpringAnimation { spring: 6; damping: 0.4 } }
        Text {
            id: lbl
            anchors.centerIn: parent
            text: parent.text
            color: parent.danger ? Theme.onErrorContainer : Theme.onSecondaryContainer
            font.family: root.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        MouseArea { id: press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    Cell {
        first: true
        Text { text: "Iris Shell"; color: Theme.onSurface; font.family: root.fontFamily; font.pixelSize: 20; font.weight: Font.DemiBold }
        Text { text: "Blossom 12"; color: Theme.onSurfaceVariant; font.family: root.fontFamily; font.pixelSize: 13 }
    }
    Cell {
        Text { text: "Settings file"; color: Theme.onSurface; font.family: root.fontFamily; font.pixelSize: 14; font.weight: Font.Medium }
        Text { text: Config.path; color: Theme.onSurfaceVariant; font.family: root.fontFamily; font.pixelSize: 12; elide: Text.ElideMiddle; Layout.fillWidth: true }
        RowLayout {
            Layout.topMargin: 8
            spacing: 8
            TonalButton { text: "Open file"; onClicked: Quickshell.execDetached(["xdg-open", Config.path]) }
            TonalButton { text: "Open folder"; onClicked: Quickshell.execDetached(["xdg-open", root.folder]) }
        }
    }
    Cell {
        Text { text: "Iris Theme"; color: Theme.onSurface; font.family: root.fontFamily; font.pixelSize: 14; font.weight: Font.Medium }
        Text {
            text: root.theme && root.theme.online ? "Running · source " + root.theme.source : "Not running"
            color: Theme.onSurfaceVariant
            font.family: root.fontFamily
            font.pixelSize: 12
        }
    }
    Cell {
        last: true
        Text { text: "Reset everything"; color: Theme.onSurface; font.family: root.fontFamily; font.pixelSize: 14; font.weight: Font.Medium }
        Text { text: "Removes all your changes and brings back the defaults"; color: Theme.onSurfaceVariant; font.family: root.fontFamily; font.pixelSize: 12 }
        TonalButton {
            Layout.topMargin: 8
            danger: true
            text: root.confirm ? "Click again to confirm" : "Reset all settings"
            onClicked: {
                if (root.confirm) { Config.resetAll(); root.confirm = false }
                else { root.confirm = true; confirmTimer.restart() }
            }
        }
    }
}