import QtQuick
import Iris

Rectangle {
    id: root

    property var def: ({})
    property real order: 0
    property real reveal: 1
    property bool fresh: false
    property bool editing: false
    property Component content: null
    property url contentUrl: ""
    property real uiScale: 1
    property string badge: ""
    property real slotX: 0
    property real slotY: 0

    signal remove()
    signal dragStarted()
    signal dragMoved(real cx, real cy)
    signal dragEnded()
    signal resizeStarted()
    signal resizeMoved(real dx, real dy)
    signal resizeEnded()

    readonly property var cfg: Config.data.deck
    readonly property string style: cfg.style
    readonly property color base: Theme[def.tone ?? "surfaceContainerHigh"] ?? Theme.surfaceContainerHigh

    property real born: 1
    property real gone: 0
    property bool leaving: false
    property bool dragging: false
    property bool resizing: false
    property real offX: 0
    property real offY: 0
    property real grabX: 0
    property real grabY: 0
    property real dragTx: 0
    property real dragTy: 0
    property real sx: 0
    property real sy: 0
    property real liftV: hover.hovered && !root.editing && cfg.hoverLift ? 1 : 0
    property real grab: dragging || resizing ? 1 : 0

    Behavior on liftV { Spring {} }
    Behavior on grab { Spring {} }
    Behavior on slotX { Spring {} }
    Behavior on slotY { Spring {} }
    Behavior on width { Spring {} }
    Behavior on height { Spring {} }
    Behavior on offX { enabled: !root.dragging; Spring {} }
    Behavior on offY { enabled: !root.dragging; Spring {} }

    x: slotX + offX
    y: slotY + offY
    z: dragging || resizing || Math.abs(offX) + Math.abs(offY) > 1 ? 20 : 0

    onSlotXChanged: if (dragging) offX = grabX + dragTx - slotX
    onSlotYChanged: if (dragging) offY = grabY + dragTy - slotY

    function requestRemove() {
        if (leaving) return
        leaving = true
        leaveAnim.start()
    }
    NumberAnimation { id: leaveAnim; target: root; property: "gone"; from: 0; to: 1; duration: 180; easing.type: Easing.InCubic; onFinished: root.remove() }
    NumberAnimation { id: bornAnim; target: root; property: "born"; from: 0; to: 1; duration: 460; easing.type: Easing.OutBack }
    Component.onCompleted: if (fresh) bornAnim.start()

    scale: Motion.lerp(0.86, 1, root.reveal) * Motion.lerp(0.8, 1, root.born) * (1 - 0.4 * root.gone) * (1 + 0.014 * root.liftV) * (1 + 0.04 * root.grab)
    opacity: Math.min(1, root.reveal * 1.8) * Math.min(1, root.born * 1.5) * (1 - root.gone)
    transform: Translate { y: (1 - Math.min(1, root.reveal)) * 26 }

    radius: cfg.radius + 8 * root.liftV
    color: style === "solid" ? base
         : style === "tonal" ? Theme.surfaceContainerHigh
         : style === "glass" ? Qt.alpha(base, cfg.cardOpacity)
         : "transparent"
    border.width: editing ? 2 : (style === "outline" ? 2 : 0)
    border.color: editing ? (dragging || resizing ? Theme.tertiary : Theme.primary) : base
    clip: true
    Behavior on color { ColorAnimation { duration: 250 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    HoverHandler { id: hover }

    SequentialAnimation on rotation {
        running: root.editing && !root.leaving && !root.dragging && !root.resizing
        loops: Animation.Infinite
        PauseAnimation { duration: (Math.floor(root.order * 7) % 5) * 28 }
        NumberAnimation { to: 0.6; duration: 120 }
        NumberAnimation { to: -0.6; duration: 240 }
        NumberAnimation { to: 0; duration: 120 }
    }
    onEditingChanged: if (!editing) rotation = 0
    onDraggingChanged: if (dragging) rotation = 0
    onResizingChanged: if (resizing) rotation = 0

    Loader {
        anchors.fill: parent
        active: root.contentUrl == ""
        sourceComponent: root.content
    }
    Loader {
        anchors.fill: parent
        active: root.contentUrl != ""
        source: root.contentUrl
    }

    Rectangle {
        id: overlay
        anchors.fill: parent
        color: Qt.alpha(Theme.scrim, 0.42)
        opacity: root.editing ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 160 } }

        MouseArea {
            anchors.fill: parent
            cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

            DragHandler {
                target: null
                enabled: root.editing && !root.resizing && !root.leaving
                onActiveChanged: {
                    if (active) {
                        root.sx = centroid.scenePosition.x
                        root.sy = centroid.scenePosition.y
                        root.grabX = root.slotX
                        root.grabY = root.slotY
                        root.dragTx = 0
                        root.dragTy = 0
                        root.dragging = true
                        root.dragStarted()
                    } else {
                        root.dragEnded()
                        root.dragging = false
                        root.offX = 0
                        root.offY = 0
                    }
                }
                onTranslationChanged: {
                    if (!active) return
                    root.dragTx = (centroid.scenePosition.x - root.sx) / root.uiScale
                    root.dragTy = (centroid.scenePosition.y - root.sy) / root.uiScale
                    root.offX = root.grabX + root.dragTx - root.slotX
                    root.offY = root.grabY + root.dragTy - root.slotY
                    root.dragMoved(root.x + root.width / 2, root.y + root.height / 2)
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 12
            text: root.def.name ?? ""
            color: Theme.onSurface
            font.family: Config.data.appearance.font
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Chip {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            implicitWidth: 34
            text: "✕"
            accent: true
            onClicked: root.requestRemove()
        }

        Rectangle {
            visible: root.badge !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            implicitWidth: badgeText.implicitWidth + 20
            implicitHeight: 24
            radius: 12
            color: Theme.primary
            Text {
                id: badgeText
                anchors.centerIn: parent
                text: root.badge
                color: Theme.onPrimary
                font.family: Config.data.appearance.font
                font.pixelSize: 12
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: grip
            width: 34
            height: 34
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 6
            cursorShape: Qt.SizeFDiagCursor

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Theme.primary
                opacity: root.resizing ? 1 : 0.88
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
            Rectangle {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 3
                anchors.verticalCenterOffset: 3
                width: 14
                height: 2.5
                radius: 1.25
                rotation: -45
                color: Theme.onPrimary
            }
            Rectangle {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -3
                anchors.verticalCenterOffset: -3
                width: 14
                height: 2.5
                radius: 1.25
                rotation: -45
                color: Theme.onPrimary
            }

            DragHandler {
                target: null
                enabled: root.editing && !root.dragging && !root.leaving
                onActiveChanged: {
                    if (active) {
                        root.sx = centroid.scenePosition.x
                        root.sy = centroid.scenePosition.y
                        root.resizing = true
                        root.resizeStarted()
                    } else {
                        root.resizing = false
                        root.resizeEnded()
                    }
                }
                onTranslationChanged: {
                    if (!active) return
                    root.resizeMoved((centroid.scenePosition.x - root.sx) / root.uiScale,
                                     (centroid.scenePosition.y - root.sy) / root.uiScale)
                }
            }
        }
    }
}