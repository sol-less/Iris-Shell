import QtQuick
import QtQuick.Layouts
import Iris

Item {
    id: root

    property var section: ({})
    property var allSections: []
    property string query: ""
    property var theme: null

    readonly property real contentY: flick.contentY
    signal scrolled(real y)

    readonly property string needle: query.trim().toLowerCase()
    readonly property bool searching: needle !== ""
    readonly property string fontFamily: Config.data.appearance.font
    readonly property string special: searching ? "" : (section.special ?? "")

    function matches(item, q) {
        const hay = ((item.title ?? "") + " " + (item.desc ?? "") + " " + (item.key ?? "")).toLowerCase()
        return hay.indexOf(q) !== -1
    }

    function search(q) {
        const out = []
        for (const s of allSections) {
            const name = s.label ?? s.name ?? ""
            const hit = name.toLowerCase().indexOf(q) !== -1
            for (const g of (s.groups ?? [])) {
                const rows = (g.items ?? []).filter(it => !it.hidden && (hit || matches(it, q)))
                if (rows.length > 0) out.push({ section: name, group: g.title ?? "", items: rows })
            }
        }
        return out
    }

    readonly property var blocks: searching
        ? search(needle)
        : (section.groups ?? []).map(g => ({ section: "", group: g.title ?? "", items: (g.items ?? []).filter(it => !it.hidden) }))

    property real enter: 1
    onSectionChanged: enterAnim.restart()
    NumberAnimation { id: enterAnim; target: root; property: "enter"; from: 0; to: 1; duration: Motion.slow; easing.type: Easing.OutCubic }

    Component { id: appearanceC; AppearancePanel { theme: root.theme } }
    Component { id: developerC; DeveloperPanel { theme: root.theme } }
    Component { id: aboutC; AboutPanel { theme: root.theme } }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight + 56
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        onContentYChanged: root.scrolled(contentY)

        ColumnLayout {
            id: content
            x: 8 + (1 - root.enter) * 36
            y: 8
            width: flick.width - 16
            opacity: root.enter
            spacing: 14

            Text {
                Layout.fillWidth: true
                text: root.searching ? "Search" : (root.section.label ?? root.section.name ?? "")
                color: Theme.onSurface
                font.family: root.fontFamily
                font.pixelSize: 44
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.searching ? "Results for \"" + root.query.trim() + "\"" : (root.section.sub ?? "")
                color: Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 15
                wrapMode: Text.WordWrap
            }

            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                visible: root.special !== ""
                sourceComponent: root.special === "appearance" ? appearanceC
                               : root.special === "developer" ? developerC
                               : root.special === "about" ? aboutC : null
            }

            Repeater {
                model: root.blocks

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    Layout.fillWidth: true
                    visible: modelData.items.length > 0
                    implicitHeight: visible ? cardCol.implicitHeight + 44 : 0
                    radius: 28
                    color: Theme.surfaceContainer

                    ColumnLayout {
                        id: cardCol
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 16

                        Text {
                            visible: text !== ""
                            text: card.modelData.section !== "" ? card.modelData.section + "  ·  " + card.modelData.group : card.modelData.group
                            color: Theme.primary
                            font.family: root.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                        Repeater {
                            model: card.modelData.items
                            delegate: SettingItem {
                                required property var modelData
                                Layout.fillWidth: true
                                spec: modelData
                            }
                        }
                    }
                }
            }

            Text {
                visible: root.searching && root.blocks.length === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 40
                text: "Nothing matches"
                color: Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 16
            }
        }
    }
}