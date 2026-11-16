import QtQuick
import QtQuick.Layouts
import Quickshell
import M3Shapes
import Iris

Rectangle {
    id: root
    readonly property string fontFamily: Config.data.appearance.font

    SystemClock { id: clock; precision: SystemClock.Minutes }

    property int offset: 0
    readonly property int fdow: Qt.locale().firstDayOfWeek % 7
    readonly property date today: clock.date
    readonly property date first: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int lead: (first.getDay() - fdow + 7) % 7

    function cellDate(i) { return new Date(first.getFullYear(), first.getMonth(), 1 - lead + i) }
    function isToday(d) {
        return d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth() && d.getDate() === today.getDate()
    }

    radius: 32
    color: Theme.surfaceContainerHigh

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: Qt.formatDate(root.first, "MMMM yyyy")
                color: Theme.onSurface
                font.family: root.fontFamily
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }
            Chip { visible: root.offset !== 0; text: "Today"; onClicked: root.offset = 0 }
            Chip { implicitWidth: 34; text: "‹"; onClicked: root.offset-- }
            Chip { implicitWidth: 34; text: "›"; onClicked: root.offset++ }
        }

        Grid {
            Layout.alignment: Qt.AlignHCenter
            columns: 7
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
                model: 7
                delegate: Item {
                    required property int index
                    width: 34; height: 26
                    Text {
                        anchors.centerIn: parent
                        text: Qt.locale().dayName((root.fdow + index) % 7, Locale.NarrowFormat)
                        color: Theme.onSurfaceVariant
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }

            Repeater {
                model: 42
                delegate: Item {
                    id: cell
                    required property int index
                    readonly property date d: root.cellDate(index)
                    readonly property bool todayCell: root.isToday(d)
                    readonly property bool inMonth: d.getMonth() === root.first.getMonth()
                    width: 34; height: 34

                    MaterialShape {
                        visible: cell.todayCell
                        anchors.centerIn: parent
                        implicitSize: 34
                        shape: MaterialShape.Cookie9Sided
                        color: Theme.primary
                    }
                    Text {
                        anchors.centerIn: parent
                        text: cell.d.getDate()
                        color: cell.todayCell ? Theme.onPrimary : (cell.inMonth ? Theme.onSurface : Theme.outline)
                        opacity: cell.inMonth || cell.todayCell ? 1 : 0.5
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        font.weight: cell.todayCell ? Font.Bold : Font.Normal
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}