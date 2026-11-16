import Iris
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../overlay"

PanelWindow {
    id: win

    readonly property int baseH: 36
    readonly property var fx: Config.data.notch
    property bool pillHidden: false
    readonly property rect pillRect: Qt.rect(mainRect.x + (screen ? (screen.width - width) / 2 : 0), mainRect.y, mainRect.width, mainRect.height)
    readonly property real pillRadius: mainRect.radius
    signal panelRequested()

    implicitHeight: 120                       // room for a taller pill, the ripple and the page dots
    color: "transparent"
    exclusiveZone: baseH + 12                 // constant: the pill growing never pushes windows around

    anchors {
        top: true
        left: true
        right: true
    }

    OverlaySources {}
    IdleInhibitor { enabled: Hud.caffeine; window: win }

    IpcHandler {
        target: "notch"
        function dnd(): void { Hud.toggleDnd() }
    }

    property real hov: fx.hoverGrow && hoverH.hovered && !Hud.active ? 1 : 0
    Behavior on hov { Spring {} }

    property real pressed: tap.pressed ? 1 : 0
    Behavior on pressed { Spring {} }

    property real lastW: 0
    property double lastT: 0
    property real vel: 0
    readonly property real jelly: fx.jelly ? Math.tanh(Math.abs(vel) / 900) : 0
    function noteWidth(w) {
        const now = Date.now()
        const dt = (now - lastT) / 1000
        if (lastT > 0 && dt > 0.001 && dt < 0.12) vel = vel * 0.6 + ((w - lastW) / dt) * 0.4
        lastT = now
        lastW = w
    }
    Timer {                                   // the width stopped: the velocity decays
        interval: 50
        repeat: true
        running: Math.abs(win.vel) > 5
        onTriggered: win.vel *= 0.55
    }

    readonly property bool vivid: fx.glow && (Cava.running || Hud.active)
    readonly property real amt: Cava.running ? 0.25 + 0.6 * Cava.level : (Hud.active ? 0.4 : 0)
    readonly property color glowColor: Hud.active && Hud.kind === "notification" && Hud.urgency >= 2
                                       ? Theme.error : Theme.primary
    property real glowT: vivid ? 1 : 0
    Behavior on glowT { Fade {} }
    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t)
    }

    MultiEffect {
        source: mainRect
        visible: !win.pillHidden
        anchors.fill: mainRect
        shadowEnabled: true
        shadowColor: win.mix(Qt.rgba(0, 0, 0, 1), win.glowColor, win.glowT)
        shadowOpacity: Motion.lerp(0.55, Math.min(0.9, 0.3 + win.amt), win.glowT)
        shadowBlur: win.fx.shadow + 0.35 * win.amt * win.glowT
        shadowVerticalOffset: 4
    }

    Rectangle {
        id: ripple
        property color tint: Theme.primary
        x: mainRect.x
        y: mainRect.y
        width: mainRect.width
        height: mainRect.height
        radius: mainRect.radius
        color: "transparent"
        border.width: 2
        border.color: tint
        opacity: 0
    }
    ParallelAnimation {
        id: rippleAnim
        NumberAnimation { target: ripple; property: "scale"; from: 1; to: 1.3; duration: 650; easing.type: Easing.OutCubic }
        NumberAnimation { target: ripple; property: "opacity"; from: 0.75; to: 0; duration: 650; easing.type: Easing.OutQuad }
    }
    function ping(c) {
        if (!fx.ripple) return
        ripple.tint = c
        rippleAnim.restart()
    }
    Connections {
        target: Hud
        function onNoteChanged() { win.ping(Hud.urgency >= 2 ? Theme.error : Theme.primary) }
        function onDndChanged() { win.ping(Theme.tertiary) }
    }

    Rectangle {
        id: mainRect

        visible: !win.pillHidden
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8

        width: notchPages.implicitWidth * (1 - overlay.progress) + overlay.implicitWidth * overlay.progress + 16 + 10 * win.hov
        height: win.baseH * (1 - overlay.progress) + overlay.implicitHeight * overlay.progress + 2 * win.hov
        radius: Math.min(height / 2, Math.max(Config.data.notch.radius, height * 0.4))
        color: Qt.alpha(Theme.surfaceContainerHigh, Config.data.notch.opacity)
        clip: true
        Behavior on color { ColorAnimation { duration: 400 } }

        scale: 1 - 0.035 * win.pressed
        transformOrigin: Item.Top
        transform: Scale {
            origin.x: mainRect.width / 2
            origin.y: 0
            xScale: 1 + 0.025 * win.jelly
            yScale: 1 - 0.06 * win.jelly
        }
        onWidthChanged: win.noteWidth(width)

        NotchPages {
            id: notchPages
            away: overlay.progress
            loop: Config.data.notch.loop
            swipeThreshold: Config.data.notch.swipeThreshold
            dragRange: Config.data.notch.dragRange
        }
        OverlayHost { id: overlay }
        PageSwipe { pages: notchPages; enabled: !Hud.active }

        HoverHandler { id: hoverH }
        TapHandler { id: tap; onDoubleTapped: win.panelRequested() }      // double-click opens the Deck

        MouseArea {                                                       // middle: Do Not Disturb, right: the Deck
            anchors.fill: parent
            acceptedButtons: Qt.MiddleButton | Qt.RightButton
            onClicked: (m) => { if (m.button === Qt.MiddleButton) Hud.toggleDnd(); else win.panelRequested() }
        }
    }

    Rectangle {
        readonly property bool show: win.fx.unreadBadge && Hud.unread > 0
        visible: !win.pillHidden
        x: mainRect.x + mainRect.width - width * 0.6
        y: mainRect.y - height * 0.35
        width: Math.max(18, badgeText.implicitWidth + 10)
        height: 18
        radius: 9
        color: Theme.primary
        scale: show ? 1 : 0
        opacity: win.pillHidden ? 0 : 1
        Behavior on opacity { enabled: !win.pillHidden; NumberAnimation { duration: 200 } }
        Behavior on scale { Spring {} }

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: Hud.unread > 9 ? "9+" : Hud.unread
            color: Theme.onPrimary
            font.family: Config.data.appearance.font
            font.pixelSize: 10
            font.weight: Font.Bold
        }
    }

    PageDots {
        anchors.horizontalCenter: mainRect.horizontalCenter
        y: mainRect.y + mainRect.height + 8
        count: notchPages.pageCount
        position: notchPages.pos
        shown: notchPages.moving && !Hud.active
    }

    mask: Region {
        item: mainRect
    }
}