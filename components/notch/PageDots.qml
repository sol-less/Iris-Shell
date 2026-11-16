import QtQuick
import Iris

Rectangle {
    id: root
    property int count: 3
    property real position: 0
    property bool shown: false

    readonly property int cur: ((Math.round(position) % count) + count) % count

    width: row.implicitWidth + 20
    height: 20
    radius: height / 2
    color: Theme.surfaceContainerHigh
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.6
    Behavior on opacity { NumberAnimation { duration: 180 } }
    Behavior on scale { Spring {} }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: root.count
            delegate: Rectangle {
                required property int index
                readonly property bool active: index === root.cur
                width: active ? 18 : 6                   // the active dot stretches into a pill
                height: 6
                radius: 3
                color: active ? Theme.primary : Theme.outlineVariant
                Behavior on width { Spring {} }
                Behavior on color { ColorAnimation { duration: 160 } }
            }
        }
    }
}