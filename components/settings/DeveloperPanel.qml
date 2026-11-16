import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Iris

ColumnLayout {
    id: root
    property var theme: null
    readonly property string fontFamily: Config.data.appearance.font

    property string report: ""
    property bool copied: false
    property bool building: false
    property int pending: 0
    property string logText: ""
    property string hyprText: ""
    property var targets: []
    property string result: ""
    property string lastCall: ""
    property int lastCode: 0

    spacing: 12

    FileView { id: ver; path: Quickshell.shellDir + "/VERSION"; blockLoading: true }
    readonly property string version: {
        try { return ver.text().trim() } catch (e) { return "unknown" }
    }

    function redact(s) {
        const home = Quickshell.env("HOME")
        return home ? s.split(home).join("~") : s
    }

    function build() {
        building = true
        pending = 2
        report = ""
        logProc.running = true
        hyprProc.running = true
    }
    function step() {
        pending--
        if (pending <= 0) compose()
    }
    function compose() {
        const cfg = JSON.parse(JSON.stringify(Config.data))
        if (cfg.deck) delete cfg.deck.note
        const screens = Quickshell.screens.map(s => s.name + " " + s.width + "x" + s.height).join(", ")
        const parts = [
            "Iris Shell bug report",
            "",
            "Version: " + version,
            "Qt: " + Qt.version,
            "Screens: " + screens,
            "Iris Theme: " + (theme && theme.online ? "running" : "not running"),
            "",
            "Hyprland:",
            hyprText.trim(),
            "",
            "Settings (the Deck note is left out):",
            JSON.stringify(cfg, null, 2),
            "",
            "Log (last 80 lines):",
            logText.trim()
        ]
        report = redact(parts.join("\n"))
        building = false
    }

    function parse(raw) {
        const out = []
        let cur = null
        for (const line of raw.split("\n")) {
            const t = line.match(/^target\s+(\S+)/)
            if (t) { cur = { name: t[1], fns: [] }; out.push(cur); continue }
            const f = line.match(/^\s+function\s+(\w+)\((.*)\):\s*(\w+)/)
            if (f && cur) {
                const args = f[2].trim() === "" ? [] : f[2].split(",").map(a => {
                    const p = a.split(":")
                    return { name: p[0].trim(), type: (p[1] || "").trim() }
                })
                cur.fns.push({ name: f[1], args: args, ret: f[3] })
            }
        }
        targets = out
    }

    function call(target, name, argv) {
        if (runner.running) return
        lastCall = target + "." + name
        result = "…"
        runner.command = ["qs", "ipc", "call", target, name].concat(argv)
        runner.running = true
    }
    function finish() {
        const o = runOut.text.trim()
        const e = runErr.text.trim()
        result = lastCall + (lastCode === 0 ? " ok" : " failed (" + lastCode + ")")
               + (o || e ? "\n" + (lastCode === 0 ? o : (e || o)) : "")
    }

    Component.onCompleted: showProc.running = true

    Process {
        id: logProc
        command: ["sh", "-c", "f=$(ls -t \"$HOME\"/.local/state/quickshell/logs/*/log 2>/dev/null | head -n 1); if [ -n \"$f\" ]; then tail -n 80 \"$f\"; else echo '(no log file found)'; fi"]
        stdout: StdioCollector { onStreamFinished: { root.logText = this.text; root.step() } }
    }
    Process {
        id: hyprProc
        command: ["sh", "-c", "hyprctl version 2>/dev/null | head -n 4"]
        stdout: StdioCollector { onStreamFinished: { root.hyprText = this.text; root.step() } }
    }
    Process {
        id: showProc
        command: ["qs", "ipc", "show"]
        stdout: StdioCollector { onStreamFinished: root.parse(this.text) }
    }
    Process {
        id: runner
        stdout: StdioCollector { id: runOut }
        stderr: StdioCollector { id: runErr }
        onExited: (code) => { root.lastCode = code; settle.restart() }
    }
    Timer { id: settle; interval: 120; onTriggered: root.finish() }
    Timer { id: copiedTimer; interval: 1600; onTriggered: root.copied = false }

    DevCard {
        title: "Developer options"
        subtitle: "Turn this off to hide the page again. Unlock it again by tapping the badge in About."
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Enabled"
                color: Theme.onSurface
                font.family: root.fontFamily
                font.pixelSize: 14
            }
            Toggle {
                checked: Config.data.developer?.enabled ?? false
                onToggled: (v) => Config.set("developer.enabled", v)
            }
        }
    }

    DevCard {
        title: "Animation speed"
        subtitle: "Slows down or speeds up the shell's animations. 1× is normal."
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ValueSlider {
                Layout.fillWidth: true
                from: 0.25
                to: 3
                step: 0.05
                unit: "×"
                value: Config.data.developer?.animScale ?? 1
                onMoved: (v) => Config.set("developer.animScale", v)
            }
            Chip { text: "1×"; onClicked: Config.set("developer.animScale", 1) }
        }
    }

    DevCard {
        title: "Diagnostics"
        subtitle: "Is everything running?"
        StatusPanel { Layout.fillWidth: true; theme: root.theme }
    }

    DevCard {
        title: "Bug report"
        subtitle: "Builds the text on this machine only. Nothing is sent anywhere. Read it before you share it: it has your settings and the last lines of the log, with your home folder shortened to ~."
        RowLayout {
            spacing: 8
            Chip { text: root.building ? "Building…" : "Build report"; accent: true; onClicked: root.build() }
            Chip {
                visible: root.report !== ""
                text: root.copied ? "Copied" : "Copy"
                onClicked: {
                    Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", root.report])
                    root.copied = true
                    copiedTimer.restart()
                }
            }
            Chip { visible: root.report !== ""; text: "Clear"; onClicked: root.report = "" }
        }
        Rectangle {
            visible: root.report !== ""
            Layout.fillWidth: true
            Layout.preferredHeight: 260
            radius: 16
            color: Theme.surfaceContainerHighest

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: 12
                contentWidth: width
                contentHeight: view.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                TextEdit {
                    id: view
                    width: flick.width
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    text: root.report
                    color: Theme.onSurface
                    font.family: "monospace"
                    font.pixelSize: 11
                }
            }
        }
    }

    DevCard {
        title: "IPC playground"
        subtitle: "Every qs ipc function of this shell. Fill in the arguments, then click the function. Lock asks twice."
        RowLayout {
            spacing: 8
            Chip { text: "Refresh"; onClicked: showProc.running = true }
            Text {
                text: root.targets.length + " targets"
                color: Theme.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 12
            }
        }
        Repeater {
            model: root.targets
            delegate: ColumnLayout {
                id: tgt
                required property var modelData
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: tgt.modelData.name
                    color: Theme.primary
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: tgt.modelData.fns
                        delegate: IpcFunction {
                            required property var modelData
                            target: tgt.modelData.name
                            name: modelData.name
                            args: modelData.args
                            risky: tgt.modelData.name === "lock"
                            onRun: (argv) => root.call(tgt.modelData.name, modelData.name, argv)
                        }
                    }
                }
            }
        }
        Text {
            visible: root.result !== ""
            Layout.fillWidth: true
            text: root.result
            wrapMode: Text.WordWrap
            color: root.lastCode === 0 ? Theme.onSurfaceVariant : Theme.error
            font.family: "monospace"
            font.pixelSize: 11
        }
    }
}