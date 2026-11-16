import QtQuick
import M3Shapes
import Iris

Item {
    id: root

    property var shapes: []
    property string tone: ""
    property int index: 0
    property string effects: Config.data.settings?.effects ?? "full"
    property point pointer: Qt.point(0, 0)
    property real scroll: 0
    property real dim: 1
    property bool active: true
    property bool strip: false
    property var warned: ({})

    readonly property string level: effects === "full" || effects === "reduced" || effects === "off" ? effects : "reduced"

    readonly property var table: ({
        Circle: MaterialShape.Circle,
        Square: MaterialShape.Square,
        Cookie4Sided: MaterialShape.Cookie4Sided,
        Cookie6Sided: MaterialShape.Cookie6Sided,
        Cookie7Sided: MaterialShape.Cookie7Sided,
        Cookie9Sided: MaterialShape.Cookie9Sided,
        Cookie12Sided: MaterialShape.Cookie12Sided,
        Flower: MaterialShape.Flower,
        Burst: MaterialShape.Burst,
        SoftBurst: MaterialShape.SoftBurst,
        Sunny: MaterialShape.Sunny,
        Clover4Leaf: MaterialShape.Clover4Leaf,
        Pentagon: MaterialShape.Pentagon,
        Gem: MaterialShape.Gem,
        Puffy: MaterialShape.Puffy
    })

    readonly property var combos: [
        { shapes: ["Flower", "Cookie9Sided", "Circle"], tone: "primary" },
        { shapes: ["Sunny", "Burst", "Cookie6Sided"], tone: "secondary" },
        { shapes: ["Clover4Leaf", "Cookie12Sided", "Square", "Circle"], tone: "tertiary" },
        { shapes: ["SoftBurst", "Cookie7Sided", "Pentagon"], tone: "primary" },
        { shapes: ["Gem", "Cookie4Sided", "Circle"], tone: "secondary" },
        { shapes: ["Puffy", "Flower", "Cookie9Sided", "Sunny"], tone: "tertiary" }
    ]
    readonly property var combo: combos[((index % 6) + 6) % 6]
    readonly property bool custom: shapes !== undefined && shapes !== null && shapes.length > 0
    readonly property var wanted: custom ? shapes : combo.shapes
    readonly property string toneName: tone !== "" ? tone : (custom ? "primary" : combo.tone)

    readonly property int drawn: level === "off" ? 1 : Math.min(4, wanted.length)
    readonly property bool rendering: active

    function resolve(name) {
        const v = table[name]
        if (v !== undefined) return v
        if (!warned[name]) {
            warned[name] = true
            console.warn("ShapeCluster: unknown shape " + name)
        }
        return table.Circle
    }

    visible: active
    opacity: dim

    Repeater {
        model: 4

        delegate: Item {
            id: slot
            required property int index
            readonly property real depth: [0.5, 1, 1.6, 2.2][index]
            readonly property real base: Math.min(root.width, root.height)
            readonly property real fx: root.level === "full" ? root.pointer.x * depth * 26 - root.scroll * 0.04 * depth : 0
            readonly property real fy: root.level === "full" ? root.pointer.y * depth * 20 : 0
            readonly property color tint: Theme[root.toneName + (index % 2 === 0 ? "Container" : "")]

            visible: index < root.drawn
            readonly property real k: 0.92 + 0.16 * Math.sin(root.index * 1.3 + index)
            width: root.strip ? root.height * [1.1, 0.85, 0.65, 0.5][index] * k : base * [0.64, 0.42, 0.3, 0.22][index] * k
            height: width
            x: root.strip
                ? root.width * (0.42 + 0.17 * index + 0.04 * Math.cos(root.index * 1.1 + index)) - width / 2 + fx
                : root.width * (0.62 + 0.3 * Math.cos(root.index * 1.1 + index * 1.9)) - width / 2 + fx
            y: root.strip
                ? root.height * (0.5 + 0.1 * Math.sin(root.index * 1.3 + index * 2.1)) - height / 2 + fy
                : root.height * (0.48 + 0.3 * Math.sin(root.index * 0.8 + index * 2.3)) - height / 2 + fy

            Behavior on x { Spring {} }
            Behavior on y { Spring {} }
            Behavior on width { Spring {} }

            MaterialShape {
                anchors.centerIn: parent
                implicitSize: slot.width
                shape: root.resolve(root.wanted[slot.index] ?? "Circle")
                animationDuration: root.level === "off" ? 1 : 450
                color: Qt.alpha(slot.tint, [0.85, 0.28, 0.6, 0.22][slot.index])

                NumberAnimation on rotation {
                    from: 0
                    to: slot.index % 2 === 0 ? 360 : -360
                    duration: 90000 + slot.index * 22000
                    loops: Animation.Infinite
                    running: root.level === "full" && root.rendering
                }
            }
        }
    }
}