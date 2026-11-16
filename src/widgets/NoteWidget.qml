import QtQuick
import Iris

Item {
    id: root

    TextEdit {
        id: edit
        anchors.fill: parent
        anchors.margins: 16
        text: Config.data.deck.note
        wrapMode: TextEdit.Wrap
        color: Theme.onSurface
        selectionColor: Theme.primaryContainer
        font.family: Config.data.appearance.font
        font.pixelSize: 14
        clip: true
        onTextChanged: if (activeFocus) save.restart()

        Text {
            visible: edit.text === "" && !edit.activeFocus
            text: "A quick note…"
            color: Theme.onSurfaceVariant
            font: edit.font
        }
    }
    Timer { id: save; interval: 600; onTriggered: Config.set("deck.note", edit.text) }
}