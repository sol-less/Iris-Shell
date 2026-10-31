import Iris
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    height: parent.height
    implicitWidth: rowHandler.width

    RowLayout {
        id: rowHandler

        anchors.centerIn: parent

        Repeater {
            model: Applications

            delegate: Item {
                id: appEntry
                required property var modelData
                required property int index
                width: 20
                height: 20

                IconImage {
                    anchors.fill: parent
                    source: Quickshell.iconPath(appEntry.modelData.icon)
                    scale: mouseHandler.containsMouse ? 1.2 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutQuint
                        }
                    }
                }

                MouseArea {
                    id: mouseHandler
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        let app = appEntry.modelData.appId
                        Applications.launchById(app)
                    }
                }
            }
        }
    }

}
