import QtQuick
import QtQuick.Layouts
import Iris

GridLayout {
    id: root
    property string title: ""
    property string description: ""
    property bool wide: false
    default property alias control: slot.data

    columns: wide ? 1 : 2
    columnSpacing: 28
    rowSpacing: 14

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            text: root.title
            color: Theme.onSurface
            font.family: Config.data.appearance.font
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
        Text {
            visible: root.description !== ""
            Layout.fillWidth: true
            text: root.description
            color: Theme.onSurfaceVariant
            font.family: Config.data.appearance.font
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
    }

    Item {
        id: slot
        Layout.fillWidth: root.wide
        Layout.alignment: root.wide ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
        Layout.preferredWidth: root.wide ? -1 : childrenRect.width
        Layout.preferredHeight: childrenRect.height
    }
}