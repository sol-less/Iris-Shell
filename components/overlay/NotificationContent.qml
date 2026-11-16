import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import M3Shapes
import Iris

Item {
    id: root

    property string app: ""
    property string summary: ""
    property string body: ""
    property string icon: ""
    property string image: ""
    property int urgency: 1
    property var actions: []
    property bool interactive: false         // only the layer that is showing now takes clicks

    readonly property string fontFamily: Config.data.appearance.font
    readonly property bool hasActions: actions.length > 0 && Config.data.notifications.showActions

    function clean(s) {                                  // plain text: no markup, no newlines
        return s.replace(/<[^>]*>/g, "")
                .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"")
                .replace(/&#39;/g, "'").replace(/&amp;/g, "&")
                .replace(/\s*\n\s*/g, " ").trim()
    }
    readonly property string titleText: clean(summary !== "" ? summary : app)
    readonly property string bodyText: clean(body)

    readonly property string iconSource: {
        if (image !== "") return image
        if (icon.startsWith("/")) return "file://" + icon
        if (icon !== "") return Quickshell.iconPath(icon, true)
        return ""
    }

    implicitWidth: Math.min(480, Math.max(col.implicitWidth, actionsRow.visible ? actionsRow.implicitWidth : 0) + 86)
    implicitHeight: hasActions ? 102 : 64

    MaterialShape {                                      // tonal tile, the shape tells the urgency
        x: 10
        y: 9
        implicitSize: 46
        shape: root.urgency >= 2 ? MaterialShape.SoftBurst
             : (root.urgency === 0 ? MaterialShape.Circle : MaterialShape.Cookie9Sided)
        color: root.urgency >= 2 ? Theme.errorContainer
             : (root.urgency === 0 ? Theme.surfaceContainerHighest : Theme.primaryContainer)

        IconImage {
            visible: root.iconSource !== ""
            anchors.centerIn: parent
            implicitSize: 28
            source: root.iconSource
        }
        Text {
            visible: root.iconSource === ""
            anchors.centerIn: parent
            text: (root.app !== "" ? root.app : root.titleText).charAt(0).toUpperCase()
            color: root.urgency >= 2 ? Theme.onErrorContainer : Theme.onPrimaryContainer
            font.family: root.fontFamily
            font.pixelSize: 18
            font.weight: Font.Bold
        }
    }

    ColumnLayout {
        id: col
        x: 70
        y: 10
        spacing: 1

        Text {
            Layout.maximumWidth: 340
            Layout.preferredWidth: Math.min(implicitWidth, 340)
            text: root.titleText
            textFormat: Text.PlainText
            color: Theme.onSurface
            font.family: root.fontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
            maximumLineCount: 1
            elide: Text.ElideRight
        }
        Text {
            visible: root.bodyText !== ""
            Layout.maximumWidth: 340
            Layout.preferredWidth: Math.min(implicitWidth, 340)
            text: root.bodyText
            textFormat: Text.PlainText
            color: Theme.onSurfaceVariant
            font.family: root.fontFamily
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    Row {                                                // action buttons (at most two)
        id: actionsRow
        visible: root.hasActions
        x: 70
        y: 66
        spacing: 8

        Repeater {
            model: root.actions.slice(0, 2)
            delegate: Rectangle {
                id: chip
                required property var modelData
                implicitWidth: lbl.implicitWidth + 28
                implicitHeight: 28
                radius: press.pressed ? 9 : 14
                color: Theme.secondaryContainer
                Behavior on radius { Spring {} }

                Text {
                    id: lbl
                    anchors.centerIn: parent
                    text: chip.modelData.text
                    color: Theme.onSecondaryContainer
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                MouseArea {
                    id: press
                    anchors.fill: parent
                    enabled: root.interactive
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hud.invokeAction(Hud.noteId, chip.modelData.id)
                }
            }
        }
    }
}