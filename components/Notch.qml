import Iris
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "launcher"
import "shell"

PanelWindow {
    id: win

    property int page: 0
    readonly property int pageCount: 2
    property real swipeThreshold: 20
    property real dragRange: 240
    property real pos: 0
    readonly property real t: Math.max(0, Math.min(1, pos))

    function go(p) {
        page = Math.max(0, Math.min(pageCount - 1, p));
        anim.stop();
        anim.to = page;
        anim.start();
    }

    implicitHeight: 56
    color: "transparent"
    exclusiveZone: mainRect.height + 12

    anchors {
        top: true
        left: true
        right: true
    }

    NumberAnimation {
        id: anim

        target: win
        property: "pos"
        duration: 320
        easing.type: Easing.OutCubic
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
        width: stage.implicitWidth + 12
        radius: 12
        color: Theme.surface

        Item {
            id: stage

            anchors.centerIn: parent
            width: implicitWidth
            height: parent.height
            implicitWidth: notchPage.width * (1 - win.t) + otherPage.width * win.t
            clip: true

            Item {
                id: notchPage

                width: notchRow.implicitWidth
                height: stage.height
                x: (stage.width - width) / 2 + (0 - win.pos) * stage.width
                opacity: 1 - Math.min(1, Math.abs(0 - win.pos))

                RowLayout {
                    id: notchRow

                    height: parent.height

                    ClockSwap {
                    }

                    Cava {
                    }

                }

            }

            Item {
                id: otherPage

                width: launcher.implicitWidth + 24
                height: stage.height
                x: (stage.width - width) / 2 + (1 - win.pos) * stage.width
                opacity: 1 - Math.min(1, Math.abs(1 - win.pos))

                Launcher {
                    id: launcher

                    anchors.centerIn: parent
                }

            }

        }

        DragHandler {
            // too small: snap back
            // swipe left: next
            // swipe right: back to Notch

            id: swipe

            property real startPos: 0
            property real lastX: 0

            target: null
            yAxis.enabled: false
            onActiveChanged: {
                if (active) {
                    anim.stop();
                    startPos = win.pos;
                    lastX = 0;
                } else {
                    // decide using the last value seen while dragging
                    if (lastX < -win.swipeThreshold)
                        win.go(win.page + 1);
                    else if (lastX > win.swipeThreshold)
                        win.go(win.page - 1);
                    else
                        win.go(win.page);
                }
            }
            onCentroidChanged: {
                if (!active)
                    return ;

                lastX = centroid.scenePosition.x - centroid.scenePressPosition.x;
                // dragging left moves toward the next page, and the pages follow the cursor
                win.pos = Math.max(0, Math.min(win.pageCount - 1, startPos - lastX / win.dragRange));
            }
        }

    }

    mask: Region {
        item: mainRect
    }

}
