import Iris
import M3Shapes
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var entry: ({
    })
    property int order: 0
    property bool animate: false
    property bool sideways: false // swipe left or right instead of up
    readonly property string fontFamily: Config.data.appearance.font
    readonly property bool critical: (entry.urgency ?? 1) >= 2
    property real pull: 0
    property bool leaving: false
    property real appear: animate ? 0 : 1

    function dismiss() {
        if (leaving)
            return ;

        leaving = true;
        leaveAnim.to = sideways ? (pull >= 0 ? 320 : -320) : -150;
        leaveAnim.start();
    }

    function ago(ms) {
        const s = Math.max(0, (Date.now() - ms) / 1000);
        if (s < 60)
            return "now";

        if (s < 3600)
            return Math.floor(s / 60) + " min";

        if (s < 86400)
            return Math.floor(s / 3600) + " h";

        return Math.floor(s / 86400) + " d";
    }

    width: 280
    height: 126
    opacity: appear
    scale: 0.86 + 0.14 * appear
    Component.onCompleted: {
        if (root.animate)
            appearAnim.start();

    }

    NumberAnimation {
        id: leaveAnim

        target: root
        property: "pull"
        to: -150
        duration: 170
        easing.type: Easing.InCubic
        onFinished: Hud.removeHistory(root.entry.id)
    }

    DragHandler {
        id: drag

        target: null
        xAxis.enabled: root.sideways
        yAxis.enabled: !root.sideways
        onTranslationChanged: {
            if (active)
                root.pull = root.sideways ? translation.x : Math.min(0, translation.y);

        }
        onActiveChanged: {
            if (active)
                return ;

            if (Math.abs(root.pull) > 56)
                root.dismiss();
            else
                root.pull = 0;
        }
    }

    SequentialAnimation {
        id: appearAnim

        PauseAnimation {
            duration: Math.min(root.order, 8) * 45
        }

        NumberAnimation {
            target: root
            property: "appear"
            to: 1
            duration: 380
            easing.type: Easing.OutBack
        }

    }

    Rectangle {
        id: card

        width: parent.width
        height: 120
        x: root.sideways ? root.pull : 0
        y: root.sideways ? 0 : root.pull
        radius: 28
        color: root.critical ? Theme.errorContainer : (root.entry.silenced ? Theme.surfaceContainer : Theme.surfaceContainerHigh)
        opacity: 1 - Math.min(1, Math.abs(root.pull) / 150)

        HoverHandler {
            id: hover
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialShape {
                    implicitSize: 30
                    shape: root.critical ? MaterialShape.SoftBurst : MaterialShape.Cookie9Sided
                    color: root.critical ? Theme.error : Theme.primaryContainer

                    Text {
                        anchors.centerIn: parent
                        text: (root.entry.app ?? "?").charAt(0).toUpperCase()
                        color: root.critical ? Theme.onError : Theme.onPrimaryContainer
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                }

                Text {
                    Layout.fillWidth: true
                    text: root.entry.app ?? ""
                    color: root.critical ? Theme.onErrorContainer : Theme.onSurfaceVariant
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.entry.silenced === true
                    text: "silenced"
                    color: Theme.tertiary
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }

                Text {
                    text: root.ago(root.entry.time ?? 0)
                    color: root.critical ? Theme.onErrorContainer : Theme.onSurfaceVariant
                    opacity: 0.8
                    font.family: root.fontFamily
                    font.pixelSize: 11
                }

            }

            Text {
                Layout.fillWidth: true
                text: root.entry.summary || root.entry.app || ""
                color: root.critical ? Theme.onErrorContainer : Theme.onSurface
                font.family: root.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: (root.entry.body ?? "").replace(/<[^>]*>/g, "").replace(/\s*\n\s*/g, " ")
                color: root.critical ? Theme.onErrorContainer : Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

        }

        Rectangle {
            visible: hover.hovered
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            width: 24
            height: 24
            radius: 12
            color: Theme.surfaceContainerHighest

            Text {
                anchors.centerIn: parent
                text: "×"
                color: Theme.onSurface
                font.pixelSize: 16
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismiss()
            }

        }

    }

    Behavior on pull {
        enabled: !drag.active && !root.leaving

        Spring {
        }

    }

}
