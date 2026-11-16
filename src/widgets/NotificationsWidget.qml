import QtQuick
import QtQuick.Layouts
import M3Shapes
import Iris

Item {
    id: root
    readonly property string fontFamily: Config.data.appearance.font
    readonly property bool wall: width > 560 && height > 330
    readonly property bool strip: !wall && width > height * 1.7
    property bool animate: true

    function scrollBy(dx) {
        const max = Math.max(0, strip.contentWidth - strip.width)
        scrollAnim.stop()
        scrollAnim.to = Math.max(0, Math.min(max, strip.contentX + dx))
        scrollAnim.start()
    }
    NumberAnimation { id: scrollAnim; target: strip; property: "contentX"; duration: 260; easing.type: Easing.OutCubic }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: "Notifications"
                color: Theme.onSurface
                font.family: root.fontFamily
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            Text {
                visible: Hud.history.length > 0
                text: Hud.history.length
                color: Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 13
            }
            Rectangle {
                visible: Hud.missed > 0
                implicitWidth: missedText.implicitWidth + 16
                implicitHeight: 22
                radius: 11
                color: Theme.tertiaryContainer
                Text {
                    id: missedText
                    anchors.centerIn: parent
                    text: Hud.missed + " missed"
                    color: Theme.onTertiaryContainer
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
            Item { Layout.fillWidth: true }
            Chip { visible: root.strip; implicitWidth: 32; text: "‹"; onClicked: root.scrollBy(-300) }
            Chip { visible: root.strip; implicitWidth: 32; text: "›"; onClicked: root.scrollBy(300) }
            Chip { visible: Hud.history.length > 0; text: "Clear all"; onClicked: Hud.clearHistory() }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MouseArea {
                anchors.fill: parent
                enabled: root.strip
                onWheel: (w) => root.scrollBy(-(w.angleDelta.y !== 0 ? w.angleDelta.y : w.angleDelta.x) * 1.4)
            }

            GridView {
                visible: root.wall
                anchors.fill: parent
                cellWidth: 296
                cellHeight: 136
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.wall ? Hud.history : []
                delegate: NotificationCard {
                    required property int index
                    required property var modelData
                    entry: modelData
                    order: index
                    animate: root.animate
                    sideways: true
                }
            }

            ListView {
                id: strip
                visible: !root.wall
                anchors.fill: parent
                orientation: root.strip ? Qt.Horizontal : Qt.Vertical
                spacing: 10
                clip: true
                interactive: !root.strip
                boundsBehavior: Flickable.StopAtBounds
                model: root.wall ? [] : Hud.history
                delegate: NotificationCard {
                    required property int index
                    required property var modelData
                    entry: modelData
                    order: index
                    animate: root.animate
                    sideways: !root.strip
                    width: root.strip ? 280 : strip.width
                }
            }

            RowLayout {
                visible: Hud.history.length === 0
                anchors.centerIn: parent
                spacing: 14
                MaterialShape { implicitSize: 48; shape: MaterialShape.Cookie12Sided; color: Theme.primaryContainer }
                Text {
                    text: "You're all caught up"
                    color: Theme.onSurfaceVariant
                    font.family: root.fontFamily
                    font.pixelSize: 14
                }
            }
        }
    }
}