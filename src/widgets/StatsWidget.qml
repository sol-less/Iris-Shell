import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Iris

Item {
    id: root
    readonly property string fontFamily: Config.data.appearance.font
    readonly property bool tall: height > 200

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        StatRow { Layout.fillWidth: true; label: "CPU"; value: SystemStats.cpu; text: Math.round(SystemStats.cpu * 100) + "%"; running: root.visible }
        StatRow { Layout.fillWidth: true; label: "RAM"; value: SystemStats.ram; text: SystemStats.ramText; running: root.visible }
        StatRow { Layout.fillWidth: true; label: "Disk"; value: SystemStats.disk; text: Math.round(SystemStats.disk * 100) + "%"; running: root.visible }

        Item {
            visible: root.tall
            Layout.fillWidth: true
            Layout.fillHeight: true

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Theme.primary
                    strokeWidth: 2.5
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathPolyline {
                        path: {
                            const h = SystemStats.cpuHistory, n = h.length
                            if (n < 2) return []
                            const pts = []
                            for (let i = 0; i < n; i++)
                                pts.push(Qt.point(i * (root.width - 28) / (n - 1), 4 + (1 - h[i]) * (parent.height - 8)))
                            return pts
                        }
                    }
                }
            }
        }

        RowLayout {
            visible: root.height > 150
            Layout.fillWidth: true
            Text {
                text: SystemStats.temp >= 0 ? Math.round(SystemStats.temp) + " °C" : "no sensor"
                color: SystemStats.temp > 85 ? Theme.error : Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "up " + SystemStats.uptime
                color: Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 12
            }
        }
    }
}