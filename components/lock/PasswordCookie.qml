import QtQuick
import M3Shapes
import Iris

Item {
    id: root

    property real size: 17
    property bool failed: false
    property bool shown: false           // this slot has a typed character
    property bool ready: true            // false while the login area is still opening

    property real pop: 0
    property int shapeIdx: 0
    property int colorIdx: 0
    property real spin: 1                // -1 or 1: which way it turns while it grows
    readonly property bool go: shown && ready

    readonly property var shapes: [
        MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided,
        MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Flower,
        MaterialShape.Clover4Leaf, MaterialShape.Sunny, MaterialShape.SoftBurst,
        MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.Puffy
    ]
    readonly property var palette: [
        Theme.primary, Theme.secondary, Theme.tertiary,
        Theme.primaryContainer, Theme.secondaryContainer, Theme.tertiaryContainer
    ]

    visible: shown                       // an empty slot takes no space in the Row
    implicitWidth: size
    implicitHeight: size

    onGoChanged: {
        if (!go) return
        shapeIdx = Math.floor(Math.random() * shapes.length)     // rolled before it is visible
        colorIdx = Math.floor(Math.random() * palette.length)
        spin = Math.random() < 0.5 ? -1 : 1
        pop = 0
        grow.restart()
    }
    onShownChanged: {
        if (!shown) { grow.stop(); pop = 0 }     // backspace or a cleared password: gone at once
    }

    NumberAnimation {
        id: grow
        target: root
        property: "pop"
        from: 0
        to: 1
        duration: 340
        easing.type: Easing.OutBack
    }

    MaterialShape {
        anchors.centerIn: parent
        implicitSize: root.size
        shape: root.shapes[root.shapeIdx]
        animationDuration: 1             // no morph from a circle when the shape is picked
        color: root.failed ? Theme.error : root.palette[root.colorIdx]
        scale: root.pop
        rotation: (1 - root.pop) * 60 * root.spin     // a small spin while it grows
        visible: root.pop > 0.001
    }
}