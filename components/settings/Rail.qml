import QtQuick
import M3Shapes
import Iris

Rectangle {
    id: root

    property var sections: []
    property int selected: 0
    property string query: ""
    property bool armed: false

    signal selectRequested(int index)
    signal resetRequested()
    signal renameRequested(string id, string name)

    readonly property var emblems: [
        MaterialShape.Cookie9Sided, MaterialShape.Flower, MaterialShape.Sunny,
        MaterialShape.Cookie6Sided, MaterialShape.Clover4Leaf, MaterialShape.Cookie12Sided
    ]
    readonly property real rowH: 44
    readonly property real rowGap: 4

    function focusSearch() { input.forceActiveFocus() }
    function renameSelected() {
        const r = rows.itemAt(selected)
        if (r) r.beginEdit()
    }

    implicitWidth: 208
    implicitHeight: 600
    radius: 32
    color: Theme.surfaceContainer
    focus: true

    Keys.onPressed: (e) => {
        if (e.key === Qt.Key_F2) {
            root.renameSelected()
            e.accepted = true
        }
    }
    onQueryChanged: if (input.text !== query) input.text = query

    Timer { id: disarm; interval: 3000; onTriggered: root.armed = false }

    Rectangle {
        id: search
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 42
        radius: 21
        color: Theme.surfaceContainerHighest
        border.width: input.activeFocus ? 2 : 0
        border.color: Theme.primary

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            color: Theme.onSurface
            font.family: Config.data.appearance.font
            font.pixelSize: 14
            onTextChanged: root.query = text

            Text {
                visible: input.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: "Search"
                color: Theme.onSurfaceVariant
                font: input.font
            }
        }
    }

    Flickable {
        id: flick
        anchors.top: search.bottom
        anchors.topMargin: 10
        anchors.bottom: footer.top
        anchors.bottomMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        contentWidth: width
        contentHeight: stack.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: stack
            width: flick.width
            height: Math.max(1, root.sections.length * (root.rowH + root.rowGap))

            Rectangle {
                y: root.selected * (root.rowH + root.rowGap)
                width: parent.width
                height: root.rowH
                radius: 22
                color: Theme.primary
                Behavior on y { Spring {} }
            }

            Repeater {
                id: rows
                model: root.sections

                delegate: Item {
                    id: row
                    required property int index
                    required property var modelData
                    readonly property bool active: index === root.selected
                    readonly property string shown: modelData.label ?? modelData.name ?? ""
                    property bool editing: false

                    y: index * (root.rowH + root.rowGap)
                    width: stack.width
                    height: root.rowH

                    function beginEdit() {
                        field.text = shown
                        editing = true
                        field.forceActiveFocus()
                        field.selectAll()
                    }
                    function endEdit() {
                        editing = false
                        root.forceActiveFocus()
                    }

                    MaterialShape {
                        id: emblem
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: row.active ? 34 : 28
                        shape: row.active ? root.emblems[row.index % 6] : MaterialShape.Circle
                        color: row.active ? Theme.onPrimary : Theme.secondaryContainer
                        Behavior on implicitSize { Spring {} }
                    }
                    Text {
                        anchors.centerIn: emblem
                        text: row.shown.charAt(0).toUpperCase()
                        color: row.active ? Theme.primary : Theme.onSecondaryContainer
                        font.family: Config.data.appearance.font
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    Text {
                        visible: !row.editing
                        x: 52
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 62
                        elide: Text.ElideRight
                        text: row.shown
                        color: row.active ? Theme.onPrimary : Theme.onSurface
                        font.family: Config.data.appearance.font
                        font.pixelSize: 14
                        font.weight: row.active ? Font.DemiBold : Font.Medium
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    TextInput {
                        id: field
                        visible: row.editing
                        x: 52
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 62
                        clip: true
                        color: Theme.onPrimary
                        selectionColor: Theme.onPrimary
                        selectedTextColor: Theme.primary
                        font.family: Config.data.appearance.font
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        onAccepted: {
                            root.renameRequested(row.modelData.id, text)
                            row.endEdit()
                        }
                        Keys.onEscapePressed: (e) => {
                            row.endEdit()
                            e.accepted = true
                        }
                        onActiveFocusChanged: if (!activeFocus) row.editing = false
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !row.editing
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.forceActiveFocus()
                            root.selectRequested(row.index)
                        }
                        onDoubleClicked: row.beginEdit()
                    }
                }
            }
        }
    }

    Rectangle {
        id: footer
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 42
        radius: root.armed || press.pressed ? 14 : 21
        color: root.armed ? Theme.error : Theme.errorContainer
        Behavior on radius { Spring {} }
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: root.armed ? "Click again to confirm" : "Reset all settings"
            color: root.armed ? Theme.onError : Theme.onErrorContainer
            font.family: Config.data.appearance.font
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        MouseArea {
            id: press
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.armed) {
                    root.armed = false
                    disarm.stop()
                    root.resetRequested()
                } else {
                    root.armed = true
                    disarm.restart()
                }
            }
        }
    }
}