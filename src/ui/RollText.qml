import QtQuick
import Iris

Item {
    id: root
    property string text: ""
    property color color: Theme.onSurface
    property font font: Qt.font({ family: Config.data.appearance.font, pixelSize: 15, weight: Font.DemiBold })
    property bool roll: true

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    TextMetrics { id: zero; font: root.font; text: "0" }        // every digit gets the same width

    Row {
        id: row
        Repeater {
            model: root.text.length
            delegate: RollChar {
                required property int index
                ch: root.text.charAt(index)
                font: root.font
                color: root.color
                digitWidth: zero.width
                animate: root.roll
            }
        }
    }
}