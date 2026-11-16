import QtQuick
import Quickshell
import Quickshell.Io
import Iris

Scope {
    id: root

    property string mode: "dark"
    property string scheme: ""
    property string image: ""
    property string source: ""
    property bool autoMode: false
    property var templates: []
    property string lastError: ""
    property int retryMs: 3000
    readonly property bool enabled: Config.data.theme?.connect ?? true
    readonly property bool online: sock.connected

    function send(obj) {
        if (!sock.connected) return
        sock.write(JSON.stringify(obj) + "\n")
        sock.flush()
    }
    function setMode(m) { send({ cmd: "set", mode: m }) }
    function toggleMode() { send({ cmd: "toggle" }) }
    function setScheme(s) { send({ cmd: "set", scheme: s }) }
    function setAuto(on) { send({ cmd: "set", auto: on }) }
    function setImage(path, index) { send({ cmd: "image", path: path, index: index ?? 0 }) }
    function setColor(hex) { send({ cmd: "color", hex: hex }) }
    function setTemplate(name, enabled) { send({ cmd: "template", name: name, enabled: enabled }) }
    function reload() { send({ cmd: "reload" }) }

    function applyState(st) {
        mode = st.mode
        scheme = st.scheme
        image = st.image
        source = st.source
        autoMode = st.auto
        templates = st.templates
        lastError = st.error
    }

    onEnabledChanged: sock.connected = enabled
    Component.onCompleted: sock.connected = enabled

    Socket {
        id: sock
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/iris-theme.sock"
        connected: false

        parser: SplitParser {
            onRead: (line) => {
                try {
                    const msg = JSON.parse(line)
                    if (msg.state) root.applyState(msg.state)
                } catch (e) {
                    console.log("iris-theme:", e, line)
                }
            }
        }

        onConnectedChanged: if (connected) {
            root.retryMs = 3000
            root.send({ cmd: "subscribe" })
        }
    }

    Timer {
        interval: root.retryMs
        repeat: true
        running: root.enabled && !sock.connected
        onTriggered: {
            sock.connected = false
            sock.connected = true
            root.retryMs = Math.min(60000, root.retryMs * 2)
        }
    }
}