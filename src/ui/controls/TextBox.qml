import QtQuick
import Iris

Rectangle {
    id: root
    property string text: ""
    property string placeholder: ""
    signal edited(string value)

    implicitWidth: 260
    implicitHeight: 46
    radius: 23
    color: Theme.surfaceContainerHighest
    border.width: input.activeFocus ? 2 : 0
    border.color: Theme.primary
    Behavior on border.width { Spring {} }

    onTextChanged: if (!input.activeFocus) input.text = text

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        text: root.text
        color: Theme.onSurface
        selectionColor: Theme.primaryContainer
        selectedTextColor: Theme.onPrimaryContainer
        font.family: Config.data.appearance.font
        font.pixelSize: 14
        font.weight: Font.Medium
        onEditingFinished: root.edited(text)

        Text {
            visible: input.text === "" && !input.activeFocus
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: Theme.onSurfaceVariant
            font: input.font
        }
    }
}