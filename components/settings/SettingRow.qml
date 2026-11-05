import QtQuick
import QtQuick.Layouts
import Iris

GridLayout {
    id: root
    property string title: ""
    property string description: ""
    property bool wide: false                         // the control goes under the text
    default property alias control: slot.data

    columns: wide ? 1 : 2
    columnSpacing: 24
    rowSpacing: 12

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 3
        Text {
            text: root.title
            color: Theme.onSurface
            font.family: Config.data.appearance.font
            font.pixelSize: 15
            font.weight: Font.Medium
        }
        Text {
            visible: root.description !== ""
            Layout.fillWidth: true
            text: root.description
            color: Theme.onSurfaceVariant
            font.family: Config.data.appearance.font
            font.pixelSize: 12
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