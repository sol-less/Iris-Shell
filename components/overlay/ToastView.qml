import QtQuick
import QtQuick.Layouts
import M3Shapes
import Iris

Item {
    id: root
    property string text: ""

    implicitWidth: row.implicitWidth + 36
    implicitHeight: 48

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 12

        MaterialShape {
            Layout.alignment: Qt.AlignVCenter
            implicitSize: 28
            shape: MaterialShape.Cookie4Sided
            color: Theme.primaryContainer
        }
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.text
            color: Theme.onSurface
            font.family: Config.data.appearance.font
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
    }
}