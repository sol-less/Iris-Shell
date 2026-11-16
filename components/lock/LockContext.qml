import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Iris

Scope {
    id: root
    signal unlocked()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool unlocking: false            // success: the surface plays its exit animation first
    property bool showFailure: false
    property int failures: 0
    property string detail: ""                // what PAM said, shown under the field

    readonly property string service: Config.data.lock.pam

    onCurrentTextChanged: showFailure = false

    function tryUnlock() {
        if (currentText === "" || unlockInProgress || unlocking) return
        detail = ""
        unlockInProgress = true
        pam.start()
    }

    PamContext {
        id: pam
        configDirectory: root.service === "" ? Quickshell.shellDir + "/components/lock/pam" : "/etc/pam.d"
        config: root.service === "" ? "password.conf" : root.service
        user: Quickshell.env("USER")

        onPamMessage: {
            if (pam.message !== "") root.detail = pam.message
            if (this.responseRequired) this.respond(root.currentText)
        }

        onError: (err) => {
            console.log("lock: pam error", err)
            root.detail = "PAM error " + err + " (see the log, or try another PAM service in Settings)"
            root.currentText = ""
            root.showFailure = true
            root.unlockInProgress = false
        }

        onCompleted: (result) => {
            console.log("lock: pam result", result)
            if (result === PamResult.Success) {
                root.unlocking = true
                root.unlocked()
            } else {
                root.currentText = ""
                root.showFailure = true
                root.failures++
            }
            root.unlockInProgress = false
        }
    }
}