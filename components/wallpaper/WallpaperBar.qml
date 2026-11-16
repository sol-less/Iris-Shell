import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Iris

Rectangle {
    id: root

    property int pages: 1
    property int page: 0
    readonly property string fontFamily: Config.data.appearance.font

    implicitWidth: row.implicitWidth + 40
    implicitHeight: 60
    radius: height / 2
    color: Theme.surfaceContainerHigh

    readonly property var options: {
        const o = [{ label: "All", value: "all" }, { label: "★ Favorites", value: "fav" }]
        for (const c of Wallpapers.categories.slice(0, 5)) o.push({ label: c, value: "c:" + c })
        return o
    }
    readonly property string current: Wallpapers.favoritesOnly ? "fav"
                                      : (Wallpapers.category !== "" ? "c:" + Wallpapers.category : "all")

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 18

        RowLayout {                                           // search
            spacing: 10
            Layout.preferredWidth: 190

            Shape {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Theme.onSurfaceVariant
                    strokeWidth: 2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 8.5; centerY: 8.5; radiusX: 6; radiusY: 6; startAngle: 0; sweepAngle: 360 }
                }
                ShapePath {
                    strokeColor: Theme.onSurfaceVariant
                    strokeWidth: 2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    startX: 13; startY: 13
                    PathLine { x: 18; y: 18 }
                }
            }
            Text {
                Layout.fillWidth: true
                text: Wallpapers.query !== "" ? Wallpapers.query : "Type to search"
                color: Wallpapers.query !== "" ? Theme.onSurface : Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 14
                elide: Text.ElideRight
            }
        }

        Choice {                                              // categories
            options: root.options
            current: root.current
            onPicked: (v) => {
                Wallpapers.favoritesOnly = v === "fav"
                Wallpapers.category = v.startsWith("c:") ? v.substring(2) : ""
            }
        }

        Row {                                                 // page dots, the active one stretches
            spacing: 5
            visible: root.pages > 1
            Repeater {
                model: root.pages
                delegate: Rectangle {
                    required property int index
                    readonly property bool active: index === root.page
                    width: active ? 18 : 6
                    height: 6
                    radius: 3
                    color: active ? Theme.primary : Theme.outlineVariant
                    Behavior on width { Spring {} }
                    Behavior on color { ColorAnimation { duration: 160 } }
                }
            }
        }

        Text {
            text: Wallpapers.count + (Wallpapers.count === 1 ? " wallpaper" : " wallpapers")
            color: Theme.onSurfaceVariant
            font.family: root.fontFamily
            font.pixelSize: 12
        }
    }
}