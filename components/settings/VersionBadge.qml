import QtQuick
import M3Shapes
import Iris

Item {
    id: root
    property int taps: 0
    readonly property int needed: 7
    readonly property bool unlocked: Config.data.developer?.enabled ?? false
    readonly property var steps: [
        MaterialShape.Circle, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided,
        MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided,
        MaterialShape.Flower, MaterialShape.Burst
    ]
    property real kick: 0

    implicitWidth: 64
    implicitHeight: 64

    function tap() {
        kickAnim.restart()
        if (unlocked) return
        taps++
        resetTimer.interval = 2200
        resetTimer.restart()
        if (taps >= needed) {
            Config.set("developer.enabled", true)
            resetTimer.interval = 700
            resetTimer.restart()
        }
    }

    NumberAnimation { id: kickAnim; target: root; property: "kick"; from: 1; to: 0; duration: 460; easing.type: Easing.OutBack }
    Timer { id: resetTimer; interval: 2200; onTriggered: { root.taps = 0; interval = 2200 } }

    MaterialShape {
        anchors.centerIn: parent
        implicitSize: 56
        shape: root.taps > 0 ? root.steps[Math.min(root.taps, 7)] : (root.unlocked ? MaterialShape.SoftBurst : root.steps[0])
        color: root.unlocked && root.taps === 0 ? Theme.tertiaryContainer : Theme.primaryContainer
        scale: 1 + 0.18 * root.kick
        rotation: root.taps * 22
        Behavior on rotation { Spring {} }
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Text {
        anchors.centerIn: parent
        text: "B"
        color: root.unlocked && root.taps === 0 ? Theme.onTertiaryContainer : Theme.onPrimaryContainer
        font.family: Config.data.appearance.font
        font.pixelSize: 22
        font.weight: Font.Bold
    }

    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.tap() }
}