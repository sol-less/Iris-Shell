import QtQuick
import Iris

Item {
    id: root
    property var scenes: []
    signal run(var scene)

    Flow {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 12
        spacing: 8
        Repeater {
            model: root.scenes
            delegate: Chip {
                required property var modelData
                text: modelData.name
                onClicked: root.run(modelData)
            }
        }
    }
}