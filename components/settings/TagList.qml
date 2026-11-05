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
                implicitWidth: tag.implicitWidth + 28
                implicitHeight: 32
                radius: 10
                color: Theme.secondaryContainer
                scale: 1
                Component.onCompleted: pop.start()
                NumberAnimation on scale { id: pop; from: 0.6; to: 1; duration: 320; easing.type: Easing.OutBack; running: false }

                Text {
                    id: tag
                    anchors.centerIn: parent
                    text: chip.modelData + "   ×"
                    color: Theme.onSecondaryContainer
                    font.family: Config.data.appearance.font
                    font.pixelSize: 13
                }
                MouseArea {
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

        Rectangle {                                       // the "add" pill
            width: 140
            height: 32
            radius: 16
            color: add.activeFocus ? Theme.surfaceContainerHighest : "transparent"
            border.width: 1
            border.color: add.activeFocus ? Theme.primary : Theme.outlineVariant

            TextInput {
                id: add
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: Theme.onSurface
                font.family: Config.data.appearance.font
                font.pixelSize: 13
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