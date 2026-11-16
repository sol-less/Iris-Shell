import QtQuick
import QtQuick.Layouts
import Iris
import "widgets"
import "pages"

Item {
    id: root

    property real away: 0
    property bool loop: true
    readonly property int pageCount: 3
    property real swipeThreshold: 40
    property real dragRange: 120

    property real pos: 0
    property int tgt: 0
    readonly property int page: mod(tgt)
    property bool moving: false               // true while swiping or settling (for the page indicator)

    function mod(i) { return ((i % pageCount) + pageCount) % pageCount }

    SpringAnimation {
        id: spring
        target: root
        property: "pos"
        spring: Config.data.motion.spring
        damping: Config.data.motion.damping
        epsilon: 0.002
    }
    Timer { id: calm; interval: 1100; onTriggered: root.moving = false }

    function settle(n) {
        if (!loop) n = Math.max(0, Math.min(pageCount - 1, n))
        tgt = n
        moving = true
        calm.restart()
        spring.stop()
        spring.to = n
        spring.start()
    }
    function step(d) { settle(tgt + d) }
    function go(p) {                          // jump to a page the short way round
        let d = p - page
        if (d > pageCount / 2) d -= pageCount
        if (d < -pageCount / 2) d += pageCount
        settle(tgt + d)
    }

    property real dragStartPos: 0
    function dragStart() { spring.stop(); tgt = Math.round(pos); dragStartPos = pos; moving = true; calm.stop() }
    function dragMove(dx) {
        const p = dragStartPos - dx / dragRange
        pos = loop ? p : Math.max(0, Math.min(pageCount - 1, p))
    }
    function dragEnd(dx) {
        if (dx < -swipeThreshold) step(1)
        else if (dx > swipeThreshold) step(-1)
        else settle(tgt)
    }

    function pageW(i) { const it = rep.itemAt(i); return it ? it.w : 0 }
    readonly property real cpos: loop ? pos : Math.max(0, Math.min(pageCount - 1, pos))
    readonly property int fl: Math.floor(cpos)
    readonly property real t: cpos - fl

    anchors.horizontalCenter: parent.horizontalCenter
    y: -away * parent.height
    opacity: Math.max(0, 1 - away)
    visible: away < 1
    enabled: away < 0.5
    width: implicitWidth
    height: parent.height
    implicitWidth: pageW(mod(fl)) * (1 - t) + pageW(mod(fl + 1)) * t
    clip: true

    Component {
        id: notchComp
        RowLayout {
            spacing: 10
            StatusIndicators {
                showNetwork: Config.data.notch.showNetwork
                showBattery: Config.data.notch.showBattery
            }
            ClockSwap {}
            TimerChip {}
            CavaBars {}
        }
    }
    Component { id: mediaComp; MediaPage {} }
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
        model: [notchComp, mediaComp, launcherComp]

        delegate: Item {
            id: pg
            required property int index
            required property var modelData

            readonly property real d: {
                const raw = index - root.pos
                if (!root.loop) return raw
                const v = root.mod(raw)
                return v > root.pageCount / 2 ? v - root.pageCount : v
            }
            readonly property real w: (loader.item ? loader.item.implicitWidth : 0) + (index === 0 ? 0 : 24)

            width: w
            height: root.height
            x: (root.width - width) / 2 + d * root.width
            opacity: 1 - Math.min(1, Math.abs(d))
            scale: 1 - 0.1 * Math.min(1, Math.abs(d))      // pages shrink a little as they leave
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