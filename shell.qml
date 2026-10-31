import Iris
import QtQuick
import Quickshell
import "components"

ShellRoot {
    id: root

    Component.onCompleted: {
        Cava.configPath = "~/.config/quickshell/config/cava.json";
        Applications.excludeCategories = ["X-SuSE-YaST", "Screensaver"];
        Applications.excludeNames = ["YaST"];
        console.log("exclude:", JSON.stringify(Applications.excludeCategories), JSON.stringify(Applications.excludeNames), "count:", Applications.count);
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

}
