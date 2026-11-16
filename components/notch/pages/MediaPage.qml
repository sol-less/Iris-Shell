import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Iris

Item {
    id: root

    readonly property var player: {
        const ps = Mpris.players.values
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null
    }
    readonly property bool playing: player ? player.isPlaying : false
    readonly property real length: player ? player.length : 0
    property real dragRatio: -1                              // while you drag the bar
    readonly property real ratio: dragRatio >= 0 ? dragRatio
                                  : (length > 0 && player ? Math.min(1, player.position / length) : 0)
    readonly property string fontFamily: Config.data.appearance.font

    implicitWidth: player ? row.implicitWidth : empty.implicitWidth
    implicitHeight: 36

    FrameAnimation {
        running: root.playing && root.visible
        onTriggered: if (root.player) root.player.positionChanged()
    }

    MouseArea {                                              // the wheel over the page changes the volume
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (w) => {
            const a = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
            if (a) a.volume = Math.max(0, Math.min(1.5, a.volume + (w.angleDelta.y > 0 ? 0.03 : -0.03)))
        }
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

        ClippingRectangle {                                  // squircle while playing, circle while paused
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: root.playing ? 9 : 14
            color: Theme.surfaceContainerHighest
            Behavior on radius { Spring {} }
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
            Layout.preferredWidth: 124
            spacing: 0
            Marquee {
                Layout.fillWidth: true
                text: root.player ? root.player.trackTitle : ""
                color: Theme.onSurface
                font.family: root.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Marquee {
                Layout.fillWidth: true
                text: root.player ? root.player.trackArtist : ""
                color: Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 11
            }
        }

        WavyBar {
            Layout.preferredWidth: 80
            Layout.preferredHeight: 16
            value: root.ratio
            thickness: 3
            gap: 3
            wavelength: 30 - 12 * Config.data.media.squiggle
            amplitude: root.playing ? Config.data.media.squiggle * 4.5 : 0
            running: root.playing && root.visible
            color: Theme.primary
            handleColor: Theme.primary
            trackColor: Theme.secondaryContainer
            Behavior on amplitude { NumberAnimation { duration: 250 } }

            MouseArea {                                      // drag to seek; it applies when you let go
                anchors.fill: parent
                enabled: root.player && root.player.canSeek
                onPressed: (m) => root.dragRatio = Math.max(0, Math.min(1, m.x / width))
                onPositionChanged: (m) => { if (pressed) root.dragRatio = Math.max(0, Math.min(1, m.x / width)) }
                onReleased: {
                    if (root.player && root.dragRatio >= 0) root.player.position = root.dragRatio * root.length
                    root.dragRatio = -1
                }
            }
        }

        Row {
            spacing: 2
            MediaButton { kind: "prev"; onClicked: root.player.previous() }
            MediaButton { kind: root.playing ? "pause" : "play"; filled: true; onClicked: root.player.togglePlaying() }
            MediaButton { kind: "next"; onClicked: root.player.next() }
        }
    }
}