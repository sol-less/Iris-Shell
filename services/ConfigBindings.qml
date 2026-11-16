import Iris
import QtQml.Models
import QtQuick
import Quickshell

Scope {
    id: root

    readonly property var targets: ({
        "Hud": Hud,
        "Applications": Applications,
        "Wallpapers": Wallpapers,
        "Cava": Cava
    })

    function valueOf(key) {
        let v = Config.data;
        for (const part of key.split(".")) v = v === undefined || v === null ? undefined : v[part]
        return v;
    }

    Instantiator {
        model: Config.bindings

        delegate: Binding {
            required property var modelData

            target: root.targets[modelData.object] ?? null
            property: modelData.property
            value: root.valueOf(modelData.key)
            when: root.targets[modelData.object] !== undefined && !(modelData.skipEmpty && root.valueOf(modelData.key) === "")
        }

    }

    Connections {
        function onDndChanged() {
            Config.set("notifications.dnd", Hud.dnd);
        }

        target: Hud
    }

    Connections {
        function onAppLaunched(appId) {
            const u = Object.assign({
            }, Config.data.launcher.usage ?? {
            });
            u[appId] = (u[appId] ?? 0) + 1;
            Config.set("launcher.usage", u);
        }

        target: Applications
    }

}
