import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import Iris

Item {
    id: root

    readonly property var player: {
        const ps = Mpris.players.values
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null
    }
    readonly property bool playing: player ? player.isPlaying : false
    readonly property real ratio: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0
    readonly property string fontFamily: "Inter"

    component Btn: Text {
        signal clicked()
        color: Theme.onSurface
        font.pixelSize: 11
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    implicitWidth: player ? row.implicitWidth : empty.implicitWidth
    implicitHeight: 36

    // keeps the progress moving while it plays
    FrameAnimation {
        running: root.playing && root.visible
        onTriggered: if (root.player) root.player.positionChanged()
    }

    Text {
        id: empty
        visible: root.player === null
        anchors.centerIn: parent
        text: "Nothing playing"
        color: Theme.onSurfaceVariant
        font.family: root.fontFamily
        font.pixelSize: 12
    }

    RowLayout {
        id: row
        visible: root.player !== null
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        ClippingRectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 8
            color: Theme.surfaceContainerHigh
            Image {
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                sourceSize.width: 56
                sourceSize.height: 56
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 120
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: root.player ? root.player.trackTitle : ""
                color: Theme.onSurface
                font.family: root.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.player ? root.player.trackArtist : ""
                color: Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        WavyBar {
            id: bar
            Layout.preferredWidth: 90
            Layout.preferredHeight: 16
            value: root.ratio
            thickness: 3
            gap: 3
            wavelength: 22
            amplitude: root.playing ? 3 : 0
            color: Theme.primary
            handleColor: Theme.primary
            trackColor: Theme.surfaceContainerHighest
            Behavior on amplitude { NumberAnimation { duration: 250 } }

            NumberAnimation on phase {
                from: 0
                to: Math.PI * 2
                duration: 1500
                loops: Animation.Infinite
                running: root.playing && root.visible
            }

            MouseArea {                      // click to seek
                anchors.fill: parent
                enabled: root.player && root.player.canSeek
                onClicked: (m) => root.player.position = m.x / width * root.player.length
            }
        }

        Row {
            spacing: 12
            Btn { text: "◀◀"; onClicked: root.player.previous() }
            Btn { text: root.playing ? "❚❚" : "▶"; onClicked: root.player.togglePlaying() }
            Btn { text: "▶▶"; onClicked: root.player.next() }
        }
    }
}