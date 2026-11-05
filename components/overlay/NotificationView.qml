import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Iris

Item {
    id: root

    property string app: ""
    property string summary: ""
    property string body: ""
    property string icon: ""
    property string image: ""

    readonly property string fontFamily: Config.data.appearance.font
    readonly property real maxTextWidth: 330

    // plain, single-line text: no markup, no newlines
    function clean(s) {
        return s.replace(/<[^>]*>/g, "")
                .replace(/&lt;/g, "<").replace(/&gt;/g, ">")
                .replace(/&quot;/g, "\"").replace(/&#39;/g, "'").replace(/&amp;/g, "&")
                .replace(/\s*\n\s*/g, " ")
                .trim()
    }

    readonly property string titleText: clean(summary !== "" ? summary : app)
    readonly property string bodyText: clean(body)

    // "" means: no usable icon, so show the letter badge
    readonly property string iconSource: {
        if (image !== "") return image
        if (icon.startsWith("/")) return "file://" + icon
        if (icon !== "") return Quickshell.iconPath(icon, true)   // "" if the theme has no such icon
        return ""
    }

    implicitWidth: Math.min(400, row.implicitWidth + 24)
    implicitHeight: 36

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 10

        IconImage {
            visible: root.iconSource !== ""
            implicitSize: 24
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.maximumWidth: 24
            Layout.maximumHeight: 24
            Layout.alignment: Qt.AlignVCenter
            source: root.iconSource
        }

        // fallback when there is no icon
        Rectangle {
            visible: root.iconSource === ""
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            radius: 8
            color: Theme.primaryContainer

            Text {
                anchors.centerIn: parent
                text: (root.app !== "" ? root.app : root.titleText).charAt(0).toUpperCase()
                color: Theme.onPrimaryContainer
                font.family: root.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.maximumWidth: root.maxTextWidth
                text: root.titleText
                textFormat: Text.PlainText
                color: Theme.onSurface
                font.family: root.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                lineHeight: 15
                lineHeightMode: Text.FixedHeight
                maximumLineCount: 1
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }

            Text {
                visible: root.bodyText !== ""
                Layout.maximumWidth: root.maxTextWidth
                text: root.bodyText
                textFormat: Text.PlainText
                color: Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 11
                lineHeight: 13
                lineHeightMode: Text.FixedHeight
                maximumLineCount: 1
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }
        }
    }
}