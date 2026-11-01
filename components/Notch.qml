import "."
import Iris
import QtQuick
import QtQuick.Effects
import Quickshell

PanelWindow {
    id: win

    implicitHeight: 56
    color: "transparent"
    exclusiveZone: mainRect.height + 12

    anchors {
        top: true
        left: true
        right: true
    }

    OverlaySources {
    }

    MultiEffect {
        source: mainRect
        anchors.fill: mainRect
        shadowEnabled: true
        shadowColor: "#000000"
        shadowBlur: 0.6
    }

    Rectangle {
        id: mainRect

        anchors.centerIn: parent
        height: 36
        width: notchPages.implicitWidth * (1 - overlay.progress) + overlay.implicitWidth * overlay.progress + 12
        radius: 12
        color: Theme.surface
        clip: true

        NotchPages {
            id: notchPages

            away: overlay.progress
        }

        OverlayHost {
            id: overlay
        }

        PageSwipe {
            pages: notchPages
            enabled: !Hud.active
        }

    }

    mask: Region {
        item: mainRect
    }

}
