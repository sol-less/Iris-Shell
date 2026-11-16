import QtQuick
import QtQuick.Layouts
import M3Shapes
import Iris

Rectangle {
    id: root
    property string title: ""
    property string subtitle: ""
    property string glyph: ""
    property bool on: false
    property var shapeOn: MaterialShape.Cookie9Sided
    signal clicked()

    implicitWidth: 140
    implicitHeight: 60
    radius: on ? 20 : 26
    color: on ? Theme.primaryContainer : Theme.surfaceContainerHigh
    scale: press.pressed ? 0.96 : 1
    Behavior on radius { Spring {} }
    Behavior on scale { Spring {} }
    Behavior on color { ColorAnimation { duration: 180 } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        MaterialShape {
            implicitSize: 36
            shape: root.on ? root.shapeOn : MaterialShape.Circle
            color: root.on ? Theme.primary : Theme.surfaceContainerHighest
            Text {
                anchors.centerIn: parent
                text: root.glyph
                color: root.on ? Theme.onPrimary : Theme.onSurfaceVariant
                font.family: Config.data.appearance.font
                font.pixelSize: 15
                font.weight: Font.Bold
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: root.title
                color: root.on ? Theme.onPrimaryContainer : Theme.onSurface
                font.family: Config.data.appearance.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.subtitle
                color: root.on ? Theme.onPrimaryContainer : Theme.onSurfaceVariant
                opacity: 0.8
                font.family: Config.data.appearance.font
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }
    MouseArea { id: press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}