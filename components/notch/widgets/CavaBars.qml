import QtQuick
import QtQuick.Layouts
import Iris

Item {
    id: root
    readonly property bool shown: Cava.available                    // a player is detected
    readonly property real bw: Config.data.cava.barWidth
    readonly property real sp: Config.data.cava.barSpacing
    readonly property real fullW: Math.max(0, Cava.bars * (bw + sp) - sp)

    implicitHeight: 36
    Layout.fillHeight: true
    Layout.preferredWidth: shown ? fullW + 6 : 0
    Behavior on Layout.preferredWidth { Spring {} }
    clip: true
    opacity: shown ? 1 : 0
    visible: shown || Layout.preferredWidth > 0.5
    Behavior on opacity { NumberAnimation { duration: 180 } }

    Equalizer {
        x: 3
        anchors.verticalCenter: parent.verticalCenter
        width: root.fullW
        height: Config.data.cava.height
        values: Cava.values
        running: Cava.running && root.visible
        barWidth: root.bw
        spacing: root.sp
        radius: 4
        color: Theme.primary
        colorTop: Theme.primary
        mirror: Config.data.cava.style === "mirror"
        peaks: Config.data.cava.peaks
    }
}