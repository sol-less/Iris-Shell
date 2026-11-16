import QtQuick
import QtQuick.Layouts
import Quickshell
import Iris

Item {
    id: root
    implicitHeight: 36
    implicitWidth: row.implicitWidth

    SystemClock {
        id: clock
        precision: Config.data.notch.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        RollText {
            Layout.alignment: Qt.AlignVCenter
            roll: Config.data.notch.clockRoll
            color: Theme.onSurface
            font.family: Config.data.appearance.font
            font.pixelSize: 14
            font.weight: Font.DemiBold
            text: Qt.formatDateTime(clock.date, Config.data.notch.clock24h
                      ? (Config.data.notch.showSeconds ? "HH:mm:ss" : "HH:mm")
                      : (Config.data.notch.showSeconds ? "h:mm:ss AP" : "h:mm AP"))
        }
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: Qt.formatDateTime(clock.date, "ddd d")
            color: Theme.onSurfaceVariant
            font.family: Config.data.appearance.font
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }
}