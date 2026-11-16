import QtQuick
import QtQuick.Layouts
import Iris

RowLayout {
    id: root
    property string target: ""
    property string name: ""
    property var args: []
    property bool risky: false
    property bool armed: false
    signal run(var argv)

    spacing: 6

    function values() {
        const out = []
        for (let i = 0; i < inputs.count; i++) out.push(inputs.itemAt(i).text)
        return out
    }

    Timer { id: disarm; interval: 3000; onTriggered: root.armed = false }

    Rectangle {
        implicitWidth: label.implicitWidth + 24
        implicitHeight: 32
        radius: press.pressed ? 10 : 16
        color: root.armed ? Theme.error : (root.risky ? Theme.errorContainer : Theme.secondaryContainer)
        Behavior on radius { Spring {} }
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.armed ? "Sure?" : root.name
            color: root.armed ? Theme.onError : (root.risky ? Theme.onErrorContainer : Theme.onSecondaryContainer)
            font.family: Config.data.appearance.font
            font.pixelSize: 12
            font.weight: Font.Medium
        }
        MouseArea {
            id: press
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.risky && !root.armed) { root.armed = true; disarm.restart(); return }
                root.armed = false
                root.run(root.values())
            }
        }
    }

    Repeater {
        id: inputs
        model: root.args
        delegate: Rectangle {
            id: field
            required property var modelData
            property alias text: input.text
            implicitWidth: 96
            implicitHeight: 32
            radius: 10
            color: Theme.surfaceContainerHighest

            TextInput {
                id: input
                anchors.fill: parent
                anchors.margins: 8
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: Theme.onSurface
                font.family: Config.data.appearance.font
                font.pixelSize: 12

                Text {
                    visible: input.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: field.modelData.name
                    color: Theme.onSurfaceVariant
                    font: input.font
                }
            }
        }
    }
}