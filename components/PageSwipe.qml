import QtQuick

DragHandler {
    id: swipe

    required property var pages // the NotchPages item
    property real dx: 0

    target: null
    yAxis.enabled: false
    onActiveChanged: {
        if (active) {
            dx = 0;
            pages.dragStart();
        } else {
            pages.dragEnd(dx);
        }
    }
    onCentroidChanged: {
        if (!active)
            return ;

        dx = centroid.scenePosition.x - centroid.scenePressPosition.x;
        pages.dragMove(dx);
    }
}
