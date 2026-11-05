import Iris
import QtQuick
import QtQuick.Layouts
import "pages"
import "widgets"

Item {
    // swipe left: next (the last page wraps to the first)
    // swipe right: previous (the first page wraps to the last)

    id: root

    property real away: 0
    property bool loop: true // false = stop at both ends again
    readonly property int pageCount: 3
    property real swipeThreshold: 40
    property real dragRange: 480
    property real pos: 0 // continuous: can go below 0 or above pageCount - 1
    property int tgt: 0 // the page we are heading to (unwrapped)
    readonly property int page: mod(tgt)
    // used by PageSwipe while dragging
    property real dragStartPos: 0
    readonly property int fl: Math.floor(pos)
    readonly property real t: pos - fl

    function mod(i) {
        return ((i % pageCount) + pageCount) % pageCount;
    }

    function settle(n) {
        if (!loop)
            n = Math.max(0, Math.min(pageCount - 1, n));

        tgt = n;
        anim.stop();
        anim.to = n;
        anim.start();
    }

    function step(d) {
        settle(tgt + d);
    }

    function go(p) {
        // jump to a page the short way round
        let d = p - page;
        if (d > pageCount / 2)
            d -= pageCount;

        if (d < -pageCount / 2)
            d += pageCount;

        settle(tgt + d);
    }

    function dragStart() {
        anim.stop();
        tgt = Math.round(pos);
        dragStartPos = pos;
    }

    function dragMove(dx) {
        const p = dragStartPos - dx / dragRange;
        pos = loop ? p : Math.max(0, Math.min(pageCount - 1, p));
    }

    function dragEnd(dx) {
        if (dx < -swipeThreshold)
            step(1);
        else if (dx > swipeThreshold)
            step(-1);
        else
            settle(tgt);
    }

    // width morphs between the two pages the position is between
    function pageW(i) {
        const it = rep.itemAt(i);
        return it ? it.w : 0;
    }

    anchors.horizontalCenter: parent.horizontalCenter
    y: -away * parent.height
    opacity: 1 - away
    visible: away < 1
    enabled: away < 0.5
    width: implicitWidth
    height: parent.height
    implicitWidth: pageW(mod(fl)) * (1 - t) + pageW(mod(fl + 1)) * t
    clip: true

    NumberAnimation {
        id: anim

        target: root
        property: "pos"
        duration: 320
        easing.type: Easing.OutCubic
    }

    Component {
        id: notchComp

        RowLayout {
            ClockSwap {
            }

            CavaBars {
            }

        }

    }

    Component {
        id: mediaComp

        MediaPage {
        }

    }

    Component {
        id: launcherComp

        Launcher {
            iconSize: Config.data.launcher.iconSize
            maxStripWidth: Config.data.launcher.maxWidth
            onLaunched: root.go(0)
        }

    }

    Repeater {
        id: rep

        model: [notchComp, launcherComp, mediaComp]

        delegate: Item {
            id: pg

            required property int index
            required property var modelData
            // wrapped distance from the current position, in pages (-1.5 to 1.5)
            readonly property real d: {
                const v = root.mod(index - root.pos);
                return v > root.pageCount / 2 ? v - root.pageCount : v;
            }
            readonly property real w: (loader.item ? loader.item.implicitWidth : 0) + (index === 0 ? 0 : 24)

            width: w
            height: root.height
            x: (root.width - width) / 2 + d * root.width
            opacity: 1 - Math.min(1, Math.abs(d))
            visible: opacity > 0
            enabled: root.page === index

            Loader {
                id: loader

                anchors.centerIn: parent
                height: parent.height
                sourceComponent: pg.modelData
            }

        }

    }

}
