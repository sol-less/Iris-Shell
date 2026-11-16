import QtQuick
import QtQuick.Layouts
import Iris

Item {
    id: root
    property bool shown: true
    default property alias content: holder.data

    implicitHeight: 28
    Layout.fillHeight: true
    Layout.preferredWidth: shown ? holder.childrenRect.width : 0
    Behavior on Layout.preferredWidth { Spring {} }
    clip: true
    opacity: shown ? 1 : 0
    visible: shown || Layout.preferredWidth > 0.5          // fully closed: it takes no space and no spacing
    Behavior on opacity { NumberAnimation { duration: 160 } }

    Item { id: holder; anchors.fill: parent }
}