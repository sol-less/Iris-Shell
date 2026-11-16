import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import M3Shapes
import Iris

Rectangle {
    id: root
    property bool active: false                          // the panel is open
    readonly property string fontFamily: Config.data.appearance.font

    readonly property var player: {
        const ps = Mpris.players.values
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null
    }
    readonly property bool playing: player ? player.isPlaying : false
    readonly property real length: player ? player.length : 0
    readonly property real position: player ? player.position : 0

    function fmt(s) {
        s = Math.max(0, Math.floor(s))
        const r = s % 60
        return Math.floor(s / 60) + ":" + (r < 10 ? "0" : "") + r
    }

    implicitHeight: 164
    radius: 32
    color: Theme.secondaryContainer

    FrameAnimation {
        running: root.playing && root.active
        onTriggered: if (root.player) root.player.positionChanged()
    }

    RowLayout {
        visible: root.player === null
        anchors.centerIn: parent
        spacing: 14
        MaterialShape {
            implicitSize: 56
            shape: MaterialShape.Cookie12Sided
            color: Theme.primaryContainer
        }
        Text {
            text: "Nothing playing"
            color: Theme.onSecondaryContainer
            font.family: root.fontFamily
            font.pixelSize: 16
            font.weight: Font.Medium
        }
    }

    ColumnLayout {
        visible: root.player !== null
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            ClippingRectangle {                          // circle while paused, squircle while playing
                Layout.preferredWidth: 88
                Layout.preferredHeight: 88
                radius: root.playing ? 26 : 44
                color: Theme.surfaceContainerHighest
                Behavior on radius { Spring {} }

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    sourceSize.width: 176
                    sourceSize.height: 176
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                MaterialShape {
                    visible: art.status !== Image.Ready
                    anchors.centerIn: parent
                    implicitSize: 48
                    shape: MaterialShape.Cookie9Sided
                    color: Theme.primaryContainer
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackTitle : ""
                    color: Theme.onSecondaryContainer
                    font.family: root.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackArtist : ""
                    color: Theme.onSecondaryContainer
                    opacity: 0.75
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
                Item { Layout.fillHeight: true }
                RowLayout {
                    spacing: 4
                    MediaButton { kind: "prev"; onClicked: root.player.previous() }
                    MediaButton { kind: root.playing ? "pause" : "play"; filled: true; onClicked: root.player.togglePlaying() }
                    MediaButton { kind: "next"; onClicked: root.player.next() }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: root.fmt(root.position)
                color: Theme.onSecondaryContainer
                font.family: root.fontFamily
                font.pixelSize: 11
            }
            WavyBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                value: root.length > 0 ? Math.min(1, root.position / root.length) : 0
                thickness: 4
                gap: 3
                wavelength: 26
                amplitude: root.playing ? 3 : 0
                running: root.playing && root.active
                color: Theme.primary
                handleColor: Theme.primary
                trackColor: Theme.surfaceContainerHighest

                MouseArea {                              // click to seek
                    anchors.fill: parent
                    enabled: root.player && root.player.canSeek
                    onClicked: (m) => root.player.position = m.x / width * root.length
                }
            }
            Text {
                text: root.fmt(root.length)
                color: Theme.onSecondaryContainer
                font.family: root.fontFamily
                font.pixelSize: 11
            }
        }
    }
}