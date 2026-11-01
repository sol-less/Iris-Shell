import Iris
import QtQuick
import Quickshell
import "components"
import "components/wallpaper"

ShellRoot {
    id: root

    Component.onCompleted: {
        Cava.configPath = "~/.config/quickshell/config/cava.json";
        Applications.excludeCategories = ["X-SuSE-YaST", "Screensaver"];
        Applications.excludeNames = ["YaST"];
        Wallpapers.folder = "~/.config/hypr/wallpapers"
        Wallpapers.applyScript = `
            ( command -v awww >/dev/null && awww img "$1" --transition-type grow \
            || swww img "$1" --transition-type grow ) &
            command -v matugen >/dev/null && matugen image "$1" --source-color-index 0 </dev/null
            wait
        `
        console.log(Wallpapers.applyScript)
    }

    Variants {
        model: Quickshell.screens

        delegate: Notch {
            required property var modelData

            screen: modelData
            Component.onCompleted: {
                console.log("Complete, screens:" + modelData);
            }
        }

    }

    WallpaperPicker {}

}
