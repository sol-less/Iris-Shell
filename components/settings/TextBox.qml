import QtQuick
import Iris

Rectangle {
    id: root
    property string text: ""
    property string placeholder: ""
    signal edited(string value)

    implicitWidth: 260
    implicitHeight: 44
    topLeftRadius: 14; topRightRadius: 14; bottomLeftRadius: 4; bottomRightRadius: 4
    color: Theme.surfaceContainerHighest

    onTextChanged: if (!input.activeFocus) input.text = text

    Rectangle {                                           // the active indicator
        anchors.bottom: parent.bottom
        width: parent.width
        height: input.activeFocus ? 3 : 1
        color: input.activeFocus ? Theme.primary : Theme.onSurfaceVariant
        Behavior on height { NumberAnimation { duration: 120 } }
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        text: root.text
        color: Theme.onSurface
        selectionColor: Theme.primaryContainer
        selectedTextColor: Theme.onPrimaryContainer
        font.family: Config.data.appearance.font
        font.pixelSize: 14
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