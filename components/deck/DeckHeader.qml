import QtQuick
import QtQuick.Layouts
import Iris
import "../settings"

Item {
    id: root

    property var pages: []
    property int page: 0
    property bool editing: false
    property bool active: true

    signal pageRequested(int index)
    signal renameRequested(int index, string name)
    signal editToggled()
    signal settingsRequested()
    signal addPageRequested()
    signal deletePageRequested()
    signal resetRequested()

    readonly property var current: pages[Math.min(page, Math.max(0, pages.length - 1))] ?? ({})
    readonly property string fontFamily: Config.data.appearance.font

    property real titleEnter: 1
    onPageChanged: titleAnim.restart()
    NumberAnimation { id: titleAnim; target: root; property: "titleEnter"; from: 0; to: 1; duration: Motion.slow; easing.type: Easing.OutCubic }

    function beginRename() {
        const t = tabRep.itemAt(Math.min(page, tabRep.count - 1))
        if (t) t.beginEdit()
    }

    implicitHeight: 148
    clip: true

    HoverHandler { id: hover }

    ShapeCluster {
        anchors.fill: parent
        strip: true
        shapes: root.current.shapes ?? []
        tone: root.current.tone ?? ""
        index: root.page
        pointer: Qt.point(hover.point.position.x / Math.max(1, root.width) * 2 - 1, hover.point.position.y / Math.max(1, root.height) * 2 - 1)
        active: root.active
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 56
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Theme.surface, 0) }
            GradientStop { position: 1.0; color: Theme.surface }
        }
    }

    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        Rectangle {
            implicitHeight: 42
            implicitWidth: tabRow.implicitWidth + 8
            radius: 21
            color: Theme.secondaryContainer

            Rectangle {
                readonly property Item active: tabRep.count > 0 ? tabRep.itemAt(Math.min(root.page, tabRep.count - 1)) : null
                x: active ? active.x + 4 : 4
                y: 4
                width: active ? active.width : 0
                height: 34
                radius: 17
                color: Theme.primary
                Behavior on x { Spring {} }
                Behavior on width { Spring {} }
            }
            Row {
                id: tabRow
                x: 4
                y: 4
                Repeater {
                    id: tabRep
                    model: root.pages
                    delegate: Item {
                        id: tab
                        required property int index
                        required property var modelData
                        readonly property bool active: index === root.page
                        property bool editing: false

                        width: (editing ? Math.max(80, field.contentWidth + 12) : tabLabel.implicitWidth) + 32
                        height: 34

                        function beginEdit() {
                            field.text = modelData.name
                            editing = true
                            field.forceActiveFocus()
                            field.selectAll()
                        }
                        function endEdit() {
                            editing = false
                            root.forceActiveFocus()
                        }

                        Text {
                            id: tabLabel
                            visible: !tab.editing
                            anchors.centerIn: parent
                            text: tab.modelData.name
                            color: tab.active ? Theme.onPrimary : Theme.onSecondaryContainer
                            font.family: root.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        TextInput {
                            id: field
                            visible: tab.editing
                            anchors.centerIn: parent
                            width: tab.width - 32
                            horizontalAlignment: TextInput.AlignHCenter
                            clip: true
                            color: tab.active ? Theme.onPrimary : Theme.onSecondaryContainer
                            selectionColor: Theme.onPrimary
                            selectedTextColor: Theme.primary
                            font.family: root.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold

                            Keys.priority: Keys.BeforeItem
                            Keys.onPressed: (e) => {
                                if ((e.key === Qt.Key_Left && cursorPosition === 0) || (e.key === Qt.Key_Right && cursorPosition === length))
                                    e.accepted = true
                            }
                            Keys.onEscapePressed: (e) => {
                                tab.endEdit()
                                e.accepted = true
                            }
                            onAccepted: {
                                root.renameRequested(tab.index, text)
                                tab.endEdit()
                            }
                            onActiveFocusChanged: if (!activeFocus) tab.editing = false
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: !tab.editing
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pageRequested(tab.index)
                            onDoubleClicked: tab.beginEdit()
                        }
                    }
                }
            }
        }
        Chip { visible: root.editing; implicitWidth: 38; implicitHeight: 38; text: "+"; onClicked: root.addPageRequested() }

        Item { Layout.fillWidth: true }

        Chip { visible: root.editing; text: "Delete page"; onClicked: root.deletePageRequested() }
        Chip { visible: root.editing; text: "Reset layout"; onClicked: root.resetRequested() }
        Chip { text: root.editing ? "Done" : "Edit"; accent: root.editing; onClicked: root.editToggled() }
        Chip { text: "Settings"; onClicked: root.settingsRequested() }
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 6 + (1 - root.titleEnter) * 40
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        opacity: root.titleEnter
        text: root.current.name ?? ""
        color: Theme.onSurface
        font.family: root.fontFamily
        font.pixelSize: 44
        font.weight: Font.DemiBold

        MouseArea {
            anchors.fill: parent
            onDoubleClicked: root.beginRename()
        }
    }
}