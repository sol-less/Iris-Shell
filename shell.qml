import Iris
import Quickshell
import "components/lock"
import "components/notch"
import "components/deck"
import "components/settings"
import "components/wallpaper"
import "services"

ShellRoot {
    ConfigBindings {
    }

    IrisThemeClient {
        id: iris
    }

    Notch {
        id: notch

        pillHidden: settings.shown
    }

    WallpaperPicker {
        theme: iris
        perPage: Config.data.wallpaper.perPage
        blocked: settings.shown
    }

    Deck {
        id: deck

        blocked: settings.shown
        onOpenSettings: settings.open = true
    }

    Settings {
        id: settings

        theme: iris
        pillRect: notch.pillRect
        pillRadius: notch.pillRadius
    }

    Lock {
    }

}