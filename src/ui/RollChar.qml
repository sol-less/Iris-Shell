import QtQuick
import Iris

Item {
    id: root
    property string ch: ""
    property font font
    property color color: Theme.onSurface
    property real digitWidth: 0
    property bool animate: true

    property string shown: ch
    property string old: ""
    property real t: 1
    property bool ready: false

    clip: true
    implicitWidth: /\d/.test(shown) && digitWidth > 0 ? digitWidth : cur.implicitWidth
    implicitHeight: cur.implicitHeight

    Component.onCompleted: ready = true
    onChChanged: {
        if (!ready || !animate) { shown = ch; old = ""; t = 1; return }
        old = shown
        shown = ch
        t = 0
        anim.restart()
    }
    NumberAnimation { id: anim; target: root; property: "t"; from: 0; to: 1; duration: 340; easing.type: Easing.OutCubic }

    Text {                                               // the old character leaves upwards
        visible: root.t < 1
        x: (root.width - width) / 2
        y: -root.t * root.height
        opacity: 1 - root.t
        text: root.old
        font: root.font
        color: root.color
    }
    Text {                                               // the new one comes from below
        id: cur
        x: (root.width - width) / 2
        y: (1 - root.t) * root.height
        opacity: root.t
        text: root.shown
        font: root.font
        color: root.color
    }
}