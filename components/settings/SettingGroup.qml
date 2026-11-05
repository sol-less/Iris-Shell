import QtQuick
import QtQuick.Layouts
import Iris

ColumnLayout {
    id: root
    property string title: ""
    property var items: []
    spacing: 2

    Text {
        visible: root.title !== ""
        Layout.leftMargin: 18
        Layout.bottomMargin: 8
        text: root.title
        color: Theme.primary
        font.family: Config.data.appearance.font
        font.pixelSize: 13
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
    }

    Repeater {
        model: root.items
        delegate: Rectangle {
            id: card
            required property int index
            required property var modelData
            readonly property bool first: index === 0
            readonly property bool last: index === root.items.length - 1

            Layout.fillWidth: true
            implicitHeight: row.implicitHeight + 34
            topLeftRadius: first ? 28 : 8
            topRightRadius: first ? 28 : 8
            bottomLeftRadius: last ? 28 : 8
            bottomRightRadius: last ? 28 : 8
            color: hover.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer
            Behavior on color { ColorAnimation { duration: 150 } }

            HoverHandler { id: hover }

            SettingItem {
                id: row
                spec: card.modelData
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}