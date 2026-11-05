import Quickshell
import Iris
import "components/notch"
import "components/wallpaper"
import "components/settings"
import "services"

ShellRoot {
    ConfigBindings {}
    IrisThemeClient { id: iris }

    Notch {}
    WallpaperPicker { theme: iris; perPage: Config.data.wallpaper.perPage }
    SettingsWindow { theme: iris }
}