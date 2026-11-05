import QtQuick
import Quickshell
import Iris

Scope {
    // OSD and notifications
    Binding { target: Hud; property: "squiggle"; value: Config.data.osd.squiggle }
    Binding { target: Hud; property: "osdMs"; value: Config.data.osd.ms }
    Binding { target: Hud; property: "notificationMs"; value: Config.data.notifications.ms }
    Binding { target: Hud; property: "criticalMs"; value: Config.data.notifications.criticalMs }

    // apps
    Binding { target: Applications; property: "includeHidden"; value: Config.data.apps.includeHidden }
    Binding { target: Applications; property: "includeTerminal"; value: Config.data.apps.includeTerminal }
    Binding { target: Applications; property: "excludeNames"; value: Config.data.apps.excludeNames }
    Binding { target: Applications; property: "excludeCategories"; value: Config.data.apps.excludeCategories }
    Binding {
        target: Applications; property: "terminal"; value: Config.data.apps.terminal
        when: Config.data.apps.terminal !== ""              // empty keeps $TERMINAL
    }

    // wallpapers
    Binding { target: Wallpapers; property: "folder"; value: Config.data.wallpaper.folder }

    // cava
    Binding { target: Cava; property: "bars"; value: Config.data.cava.bars }
    Binding { target: Cava; property: "framerate"; value: Config.data.cava.framerate }
    Binding { target: Cava; property: "inputMethod"; value: Config.data.cava.inputMethod }
    Binding { target: Cava; property: "onlyWhenPlaying"; value: Config.data.cava.onlyWhenPlaying }
}