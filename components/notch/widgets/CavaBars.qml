import Iris
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    readonly property bool shown: Cava.available
    readonly property real barWidth: Config.data.cava.barWidth
    readonly property real barSpacing: Config.data.cava.barSpacing
    readonly property real fullWidth: Cava.bars * barWidth + Math.max(0, Cava.bars - 1) * barSpacing
    property real progress: shown ? 1 : 0

    Layout.fillHeight: true
    Layout.preferredWidth: fullWidth * progress
    Layout.leftMargin: 8 * progress
    visible: progress > 0
    opacity: progress
    clip: true

    Row {
        width: root.fullWidth
        height: parent.height
        spacing: root.barSpacing

        Repeater {
            model: Cava.bars

            delegate: Item {
                id: bar

                required property int index

                width: root.barWidth
                height: parent.height

                Rectangle {
                    width: parent.width
                    height: Math.max(1, (Cava.values[bar.index] ?? 0) * (parent.height - 6))
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    radius: 2
                    color: Theme.primary

                    Behavior on height {
                        enabled: !Cava.running

                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutCubic
                        }

                    }

                }

            }

        }

    }

    Behavior on progress {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }

    }

}
