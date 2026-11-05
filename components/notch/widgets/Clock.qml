import QtQuick
import QtQuick.Layouts
import Quickshell
import Iris

Item {
	width: textHandler.width + 12

	SystemClock {
		id: sysClock
		precision: SystemClock.Minutes
	}

	Text {
		id: textHandler
		text: Qt.formatTime(sysClock.date, "hh:mm")
		color: Theme.primary
		font.family: Config.data.appearance.font
		font.pixelSize: 16
		font.weight: 600
		anchors.centerIn: parent
	}
}