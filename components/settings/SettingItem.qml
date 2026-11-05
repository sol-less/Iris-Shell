import QtQuick
import Iris

SettingRow {
    id: root
    required property var spec

    title: spec.title
    description: spec.desc ?? ""
    wide: spec.type === "tags"

    readonly property var value: {                    // reactive: reads Config.data
        let v = Config.data
        for (const part of spec.key.split("."))
            v = v === undefined || v === null ? undefined : v[part]
        return v
    }

    Loader {
        width: root.wide ? parent.width : (item ? item.implicitWidth : 0)
        height: item ? item.implicitHeight : 0
        sourceComponent: {
            switch (root.spec.type) {
            case "toggle": return toggleC
            case "slider": return sliderC
            case "text":   return textC
            case "tags":   return tagsC
            case "choice": return choiceC
            case "wave":   return waveC
            }
            return null
        }
    }

    Component { id: toggleC; Toggle { checked: root.value === true; onToggled: (v) => Config.set(root.spec.key, v) } }
    Component {
        id: sliderC
        ValueSlider {
            from: root.spec.min; to: root.spec.max
            step: root.spec.step ?? 1
            unit: root.spec.unit ?? ""
            value: root.value ?? 0
            onMoved: (v) => Config.set(root.spec.key, v)
        }
    }
    Component {
        id: textC
        TextBox {
            text: root.value ?? ""
            placeholder: root.spec.placeholder ?? ""
            onEdited: (t) => Config.set(root.spec.key, t)
        }
    }
    Component { id: tagsC; TagList { tags: root.value ?? []; onChanged: (l) => Config.set(root.spec.key, l) } }
    Component {
        id: choiceC
        Choice { options: root.spec.options; current: root.value; onPicked: (v) => Config.set(root.spec.key, v) }
    }
    Component {                                       // live preview of the squiggle
        id: waveC
        WavyBar {
            implicitWidth: 240
            implicitHeight: 24
            value: 0.62
            thickness: 4
            gap: 3
            wavelength: 36 - 16 * (root.value ?? 0)
            amplitude: (root.value ?? 0) * 4.5
            color: Theme.primary
            handleColor: Theme.primary
            trackColor: Theme.secondaryContainer
            NumberAnimation on phase { from: 0; to: Math.PI * 2; duration: 1500; loops: Animation.Infinite; running: root.visible }
        }
    }
}