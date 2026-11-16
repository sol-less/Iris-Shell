import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    property bool locked: false

    LockContext {
        id: ctx
        onUnlocked: exitTimer.start()
    }

    Timer {                                    // lets the surface play its success animation
        id: exitTimer
        interval: 450
        onTriggered: { root.locked = false; ctx.unlocking = false; ctx.currentText = "" }
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            ctx.currentText = ""
            ctx.unlocking = false
            ctx.failures = 0
            ctx.detail = ""
            root.locked = true
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            color: "black"
            LockSurface { anchors.fill: parent; context: ctx }
        }
    }
}