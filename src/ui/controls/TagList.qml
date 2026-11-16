import QtQuick
import Iris

Item {
    id: root
    property var tags: []
    signal changed(var list)

    implicitWidth: 340
    implicitHeight: flow.implicitHeight

    Flow {
        id: flow
        width: parent.width
        spacing: 8

        Repeater {
            model: root.tags
            delegate: Rectangle {
                id: chip
                required property int index
                required property string modelData
                implicitWidth: tag.implicitWidth + 32
                implicitHeight: 36
                radius: press.pressed ? 12 : 18
                color: Theme.secondaryContainer
                scale: 0.6
                Behavior on radius { Spring {} }
                Component.onCompleted: scale = 1
                Behavior on scale { Spring {} }

                Text {
                    id: tag
                    anchors.centerIn: parent
                    text: chip.modelData + "   ×"
                    color: Theme.onSecondaryContainer
                    font.family: Config.data.appearance.font
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
                MouseArea {
                    id: press
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const l = root.tags.slice()
                        l.splice(chip.index, 1)
                        root.changed(l)
                    }
                }
            }
        }

        Rectangle {
            width: 150
            height: 36
            radius: 18
            color: add.activeFocus ? Theme.surfaceContainerHighest : "transparent"
            border.width: 2
            border.color: add.activeFocus ? Theme.primary : Theme.outlineVariant
            Behavior on color { ColorAnimation { duration: 150 } }

            TextInput {
                id: add
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: Theme.onSurface
                font.family: Config.data.appearance.font
                font.pixelSize: 14
                onAccepted: {
                    const t = text.trim()
                    if (t !== "") root.changed([...root.tags, t])
                    text = ""
                }
                Text {
                    visible: add.text === "" && !add.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                    text: "+ add"
                    color: Theme.onSurfaceVariant
                    font: add.font
                }
            }
        }
    }
}