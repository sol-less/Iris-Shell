import QtQuick
import Quickshell.Hyprland
import Iris

Item {
    id: root
    implicitHeight: 36
    implicitWidth: row.implicitWidth
    readonly property bool numbers: Config.data.notch.workspaceNumbers

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: Hyprland.workspaces

            delegate: Rectangle {
                id: ws
                required property var modelData
                readonly property bool focused: modelData.focused
                readonly property bool occupied: (modelData.toplevels?.values?.length ?? 0) > 0
                readonly property bool urgent: modelData.urgent ?? false

                visible: modelData.id > 0                               // skip special workspaces
                width: focused ? (root.numbers ? 34 : 30) : (hover.hovered ? 18 : (occupied ? 12 : 9))
                height: focused && root.numbers ? 20 : 10
                radius: height / 2
                color: urgent ? Theme.error : (focused ? Theme.primary : (occupied ? Theme.secondary : Theme.outlineVariant))

                Behavior on width { Spring {} }
                Behavior on height { Spring {} }
                Behavior on color { ColorAnimation { duration: 180 } }

                Text {                                                  // the number of the active workspace
                    anchors.centerIn: parent
                    text: ws.modelData.id
                    color: Theme.onPrimary
                    font.family: Config.data.appearance.font
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    opacity: ws.focused && root.numbers ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                }

                SequentialAnimation on scale {                          // an urgent workspace pulses
                    running: ws.urgent
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.25; duration: 420; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 420; easing.type: Easing.InOutSine }
                }
                onUrgentChanged: if (!urgent) scale = 1

                HoverHandler { id: hover }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + ws.modelData.id)
                }
            }
        }
    }
}