import QtQuick
import QtQuick.Layouts
import Iris

Rectangle {
    id: root
    property string title: ""
    property string subtitle: ""
    default property alias content: body.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 34
    radius: 28
    color: Theme.surfaceContainer

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 22
        anchors.topMargin: 17
        anchors.bottomMargin: 17
        spacing: 8

        Text {
            visible: root.title !== ""
            text: root.title
            color: Theme.onSurface
            font.family: Config.data.appearance.font
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }
        Text {
            visible: root.subtitle !== ""
            Layout.fillWidth: true
            text: root.subtitle
            wrapMode: Text.WordWrap
            color: Theme.onSurfaceVariant
            font.family: Config.data.appearance.font
            font.pixelSize: 12
        }
        ColumnLayout { id: body; Layout.fillWidth: true; spacing: 8 }
    }
}