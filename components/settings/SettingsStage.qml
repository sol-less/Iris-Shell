import QtQuick
import Iris

Item {
    id: root

    property var theme: null
    property bool active: true
    property int selected: 0
    property string query: ""
    property string note: ""
    property string currentId: ""
    signal closeRequested()

    readonly property var names: Config.data.settings?.names ?? ({})
    readonly property var visibleSections: Config.sections.filter(s => s.id !== "developer" || (Config.data.developer?.enabled ?? false))
    readonly property var sections: visibleSections.map(s => names[s.id] ? Object.assign({}, s, { label: names[s.id] }) : s)
    readonly property var current: sections[Math.min(selected, Math.max(0, sections.length - 1))] ?? ({})

    onSelectedChanged: currentId = sections[selected]?.id ?? ""
    onSectionsChanged: {
        const i = sections.findIndex(s => s.id === currentId)
        selected = i >= 0 ? i : 0
    }

    function rename(id, raw) {
        const clean = raw.trim().slice(0, 24)
        const map = Object.assign({}, names)
        if (clean === "") delete map[id]
        else map[id] = clean
        Config.set("settings.names", map)
    }

    function resetAll() {
        Config.resetAll()
        note = "Settings reset. A backup is in iris.json.bak"
        noteTimer.restart()
    }

    function clearSearch() {
        query = ""
        rail.query = ""
    }

    focus: true
    Keys.onPressed: (e) => {
        if (e.key === Qt.Key_Escape) {
            if (query !== "") clearSearch()
            else closeRequested()
        } else if (e.key === Qt.Key_Down) selected = Math.min(sections.length - 1, selected + 1)
        else if (e.key === Qt.Key_Up) selected = Math.max(0, selected - 1)
        else if (e.key === Qt.Key_Slash) rail.focusSearch()
        else if (e.key === Qt.Key_F2) rail.renameSelected()
        else return
        e.accepted = true
    }

    Timer { id: noteTimer; interval: 3500; onTriggered: root.note = "" }

    HoverHandler { id: hover }

    ShapeCluster {
        id: cluster
        anchors.fill: parent
        shapes: root.current.shapes ?? []
        tone: root.current.tone ?? ""
        index: root.selected
        pointer: Qt.point(hover.point.position.x / Math.max(1, root.width) * 2 - 1, hover.point.position.y / Math.max(1, root.height) * 2 - 1)
        scroll: page.contentY
        dim: root.query.trim() !== "" ? 0.4 : 1
        active: root.active
        Behavior on dim { NumberAnimation { duration: 200 } }
    }

    Rail {
        id: rail
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - 40
        sections: root.sections
        selected: root.selected
        onSelectRequested: (i) => root.selected = i
        onQueryChanged: root.query = query
        onResetRequested: root.resetAll()
        onRenameRequested: (id, name) => root.rename(id, name)
    }

    SettingsPage {
        id: page
        anchors.left: rail.right
        anchors.leftMargin: 28
        anchors.right: parent.right
        anchors.rightMargin: 28
        anchors.top: parent.top
        anchors.topMargin: 28
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        section: root.current
        allSections: root.sections
        query: root.query
        theme: root.theme
    }

    Rectangle {
        anchors.horizontalCenter: page.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        implicitWidth: noteText.implicitWidth + 36
        implicitHeight: 40
        radius: 20
        color: Theme.inverseSurface
        opacity: root.note !== "" ? 1 : 0
        scale: root.note !== "" ? 1 : 0.8
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale { Spring {} }

        Text {
            id: noteText
            anchors.centerIn: parent
            text: root.note
            color: Theme.inverseOnSurface
            font.family: Config.data.appearance.font
            font.pixelSize: 13
            font.weight: Font.Medium
        }
    }
}