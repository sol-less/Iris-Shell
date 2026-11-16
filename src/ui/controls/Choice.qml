import QtQuick
import Iris

Row {
    id: root
    property var options: []
    property var current
    signal picked(var value)
    spacing: 3

    Repeater {
        model: root.options
        delegate: Rectangle {
            id: seg
            required property int index
            required property var modelData
            readonly property bool active: root.current === modelData.value
            property real lr: active || index === 0 ? 22 : 8
            property real rr: active || index === root.options.length - 1 ? 22 : 8

            implicitWidth: label.implicitWidth + 40
            implicitHeight: 44
            topLeftRadius: lr; bottomLeftRadius: lr
            topRightRadius: rr; bottomRightRadius: rr
            color: active ? Theme.primary : Theme.secondaryContainer
            scale: press.pressed ? 0.95 : 1

            Behavior on lr { Spring {} }
            Behavior on rr { Spring {} }
            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on scale { Spring {} }

            Text {
                id: label
                anchors.centerIn: parent
                text: seg.modelData.label
                color: seg.active ? Theme.onPrimary : Theme.onSecondaryContainer
                font.family: Config.data.appearance.font
                font.pixelSize: 14
                font.weight: Font.Medium
            }
            MouseArea {
                id: press
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(seg.modelData.value)
            }
        }
    }
}