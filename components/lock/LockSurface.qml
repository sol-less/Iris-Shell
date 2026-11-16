import "."
import "../notch/pages"
import "../notch/widgets"
import Iris
import M3Shapes
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    required property var context // the LockContext
    readonly property string fontFamily: Config.data.appearance.font
    readonly property real u: Math.max(0.6, Math.min(1.35, Math.min(width, height) / 800)) // scales with the screen
    readonly property string user: Quickshell.env("USER") || "you"
    readonly property bool failed: context.showFailure
    readonly property bool busy: context.unlockInProgress
    readonly property bool done: context.unlocking
    readonly property int chars: context.currentText.length
    property bool awake: false
    property real wake: awake ? 1 : 0

    function touch() {
        awake = true;
        sleepTimer.restart();
    }

    function greeting() {
        const h = clock.date.getHours();
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
    }

    Timer {
        id: sleepTimer

        interval: Config.data.lock.idleSleepMs
        onTriggered: {
            if (root.chars === 0 && !root.busy)
                root.awake = false;

        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
    }

    Image {
        id: wall

        anchors.fill: parent
        visible: false
        source: Wallpapers.current !== "" ? "file://" + Wallpapers.current : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 1280
    }

    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: Config.data.lock.blur && wall.status === Image.Ready
        blurEnabled: true
        blur: 1
        blurMax: 48
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.surface, 0.62)
    }

    MaterialShape {
        visible: Config.data.lock.shapes
        x: -root.u * 150
        y: -root.u * 170
        implicitSize: root.u * 480
        shape: MaterialShape.Cookie12Sided
        color: Theme.primaryContainer
        opacity: 0.32 * (1 - root.wake * 0.5)

        NumberAnimation on rotation {
            from: 0
            to: 360
            duration: 120000
            loops: Animation.Infinite
            running: root.visible
        }

    }

    MaterialShape {
        visible: Config.data.lock.shapes
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -root.u * 130
        anchors.bottomMargin: -root.u * 150
        implicitSize: root.u * 420
        shape: MaterialShape.Flower
        color: Theme.tertiaryContainer
        opacity: 0.28 * (1 - root.wake * 0.5)

        NumberAnimation on rotation {
            from: 360
            to: 0
            duration: 150000
            loops: Animation.Infinite
            running: root.visible
        }

    }

    TextInput {
        id: input

        width: 1
        height: 1
        opacity: 0
        echoMode: TextInput.Password
        readOnly: root.busy // not "enabled": that would drop the focus
        onTextChanged: {
            root.context.currentText = text;
            root.touch();
        }
        onAccepted: root.context.tryUnlock()
        Keys.onPressed: (e) => {
            root.touch();
            e.accepted = false;
        }
        Keys.onEscapePressed: {
            text = "";
            root.awake = false;
        }
        Component.onCompleted: forceActiveFocus()
    }

    Connections {
        function onCurrentTextChanged() {
            if (root.context.currentText !== input.text)
                input.text = root.context.currentText;

        }

        function onUnlockInProgressChanged() {
            if (!root.context.unlockInProgress)
                input.forceActiveFocus();

        }

        target: root.context
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        onPositionChanged: root.touch()
        onClicked: {
            root.touch();
            input.forceActiveFocus();
        }
    }

    ColumnLayout {
        id: stage

        anchors.centerIn: parent
        spacing: 0
        opacity: root.done ? 0 : 1
        scale: root.done ? 1.06 : 1

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: root.u * 14

            MaterialShape {
                implicitSize: root.u * (210 - 70 * root.wake)
                shape: MaterialShape.Cookie12Sided
                color: Theme.primaryContainer

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(clock.date, Config.data.notch.clock24h ? "HH" : "hh")
                    color: Theme.onPrimaryContainer
                    font.family: root.fontFamily
                    font.pixelSize: root.u * (108 - 36 * root.wake)
                    font.weight: Font.DemiBold
                }

            }

            MaterialShape {
                implicitSize: root.u * (210 - 70 * root.wake)
                shape: MaterialShape.Square
                color: Theme.tertiaryContainer

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(clock.date, "mm")
                    color: Theme.onTertiaryContainer
                    font.family: root.fontFamily
                    font.pixelSize: root.u * (108 - 36 * root.wake)
                    font.weight: Font.DemiBold
                }

            }

        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: root.u * 18
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Theme.onSurface
            font.family: root.fontFamily
            font.pixelSize: root.u * 24
            font.weight: Font.Medium
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: root.u * 14
            Layout.preferredHeight: implicitHeight * Math.max(0, 1 - root.wake)
            opacity: Math.max(0, 1 - root.wake * 2)
            text: "Press any key"
            color: Theme.onSurfaceVariant
            font.family: root.fontFamily
            font.pixelSize: root.u * 15
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: root.u * 22
            Layout.preferredWidth: root.u * 440
            Layout.preferredHeight: auth.implicitHeight * Math.max(0, root.wake)
            opacity: Math.max(0, Math.min(1, root.wake))
            clip: true

            ColumnLayout {
                id: auth

                width: parent.width
                spacing: root.u * 16

                MaterialShape {
                    Layout.alignment: Qt.AlignHCenter
                    implicitSize: root.u * 84
                    shape: root.done ? MaterialShape.Circle : root.failed ? MaterialShape.Burst : root.busy ? MaterialShape.Cookie6Sided : root.chars > 0 ? MaterialShape.Cookie9Sided : MaterialShape.Cookie12Sided
                    color: root.done ? Theme.primary : (root.failed ? Theme.errorContainer : Theme.secondaryContainer)

                    Text {
                        visible: !root.done
                        anchors.centerIn: parent
                        text: root.user.charAt(0).toUpperCase()
                        color: root.failed ? Theme.onErrorContainer : Theme.onSecondaryContainer
                        font.family: root.fontFamily
                        font.pixelSize: root.u * 34
                        font.weight: Font.Bold
                    }

                    Shape {
                        visible: root.done
                        anchors.centerIn: parent
                        width: 34
                        height: 34
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            strokeColor: Theme.onPrimary
                            strokeWidth: 3.4
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin

                            PathPolyline {
                                path: [Qt.point(7, 18), Qt.point(14, 25), Qt.point(27, 10)]
                            }

                        }

                    }

                }

                Rectangle {
                    id: pill

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: root.u * 380
                    Layout.preferredHeight: root.u * 66
                    radius: height / 2
                    color: root.failed ? Theme.errorContainer : Theme.surfaceContainerHigh
                    border.width: input.activeFocus ? 2 : 0
                    border.color: Theme.primary

                    SequentialAnimation {
                        id: shakeAnim

                        NumberAnimation {
                            target: shake
                            property: "x"
                            to: -18
                            duration: 50
                        }

                        NumberAnimation {
                            target: shake
                            property: "x"
                            to: 18
                            duration: 80
                        }

                        NumberAnimation {
                            target: shake
                            property: "x"
                            to: -12
                            duration: 70
                        }

                        NumberAnimation {
                            target: shake
                            property: "x"
                            to: 8
                            duration: 60
                        }

                        NumberAnimation {
                            target: shake
                            property: "x"
                            to: 0
                            duration: 60
                        }

                    }

                    Connections {
                        function onShowFailureChanged() {
                            if (root.context.showFailure)
                                shakeAnim.restart();

                        }

                        target: root.context
                    }

                    Text {
                        visible: root.chars === 0
                        x: root.u * 30
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Password"
                        color: root.failed ? Theme.onErrorContainer : Theme.onSurfaceVariant
                        font.family: root.fontFamily
                        font.pixelSize: root.u * 17
                    }

                    Row {
                        x: root.u * 30
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.u * 7

                        Repeater {
                            model: 12 // a fixed number, so the slots are never rebuilt

                            delegate: PasswordCookie {
                                required property int index

                                size: root.u * 17
                                shown: index < root.chars
                                failed: root.failed
                                ready: root.wake > 0.95 // wait until the login area has finished opening
                            }

                        }

                    }

                    MaterialShape {
                        anchors.right: parent.right
                        anchors.rightMargin: root.u * 7
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: root.u * 52
                        shape: root.busy ? MaterialShape.Cookie6Sided : MaterialShape.Circle
                        color: Theme.primary
                        opacity: root.chars > 0 ? 1 : 0.45

                        Shape {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            preferredRendererType: Shape.CurveRenderer

                            ShapePath {
                                strokeColor: Theme.onPrimary
                                strokeWidth: 2.4
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                joinStyle: ShapePath.RoundJoin
                                startX: 5
                                startY: 12

                                PathLine {
                                    x: 19
                                    y: 12
                                }

                                PathMove {
                                    x: 13
                                    y: 6
                                }

                                PathLine {
                                    x: 19
                                    y: 12
                                }

                                PathLine {
                                    x: 13
                                    y: 18
                                }

                            }

                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.context.tryUnlock()
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }

                        }

                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }

                    }

                    transform: Translate {
                        id: shake
                    }

                }

                WavyBar {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: root.u * 140
                    Layout.preferredHeight: root.u * 14
                    visible: root.busy
                    running: root.busy
                    value: 1
                    thickness: 4
                    amplitude: 3
                    color: Theme.primary
                    handleColor: Theme.primary
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.done ? "Welcome back" : root.failed ? "Wrong password" + (root.context.failures > 1 ? "  ·  attempt " + root.context.failures : "") : root.busy ? "Checking…" : root.greeting() + ", " + root.user
                    color: root.failed ? Theme.error : Theme.onSurfaceVariant
                    font.family: root.fontFamily
                    font.pixelSize: root.u * 15
                    font.weight: Font.Medium
                }

                Text {
                    visible: root.failed && root.context.detail !== ""
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: root.u * 400
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: root.context.detail
                    color: Theme.onSurfaceVariant
                    font.family: root.fontFamily
                    font.pixelSize: root.u * 12
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: root.u * 6
                    spacing: root.u * 8

                    PowerChip {
                        u: root.u
                        text: "Sleep"
                        onActivated: Quickshell.execDetached(["systemctl", "suspend"])
                    }

                    PowerChip {
                        u: root.u
                        text: "Restart"
                        confirm: true
                        onActivated: Quickshell.execDetached(["systemctl", "reboot"])
                    }

                    PowerChip {
                        u: root.u
                        text: "Shut down"
                        confirm: true
                        onActivated: Quickshell.execDetached(["systemctl", "poweroff"])
                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 320
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }

        }

    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: root.u * 36
        height: root.u * 48
        width: status.implicitWidth + root.u * 44
        radius: height / 2
        color: Theme.surfaceContainerHigh

        StatusIndicators {
            id: status

            anchors.centerIn: parent
        }

    }

    Rectangle {
        visible: Mpris.players.values.length > 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.u * 36
        height: root.u * 60
        width: media.implicitWidth + root.u * 40
        radius: height / 2
        color: Theme.surfaceContainerHigh

        MediaPage {
            id: media

            anchors.centerIn: parent
        }

    }

    Behavior on wake {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }

    }

}
