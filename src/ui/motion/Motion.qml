pragma Singleton
import QtQuick
import Iris

QtObject {
    readonly property real timeScale: Math.max(0.25, Math.min(3, Config.data.developer?.animScale ?? 1))

    readonly property real spring: Math.min(20, Config.data.motion.spring / (timeScale * timeScale))
    readonly property real damping: Config.data.motion.damping

    readonly property int fast: Math.round(120 * timeScale)
    readonly property int base: Math.round(220 * timeScale)
    readonly property int slow: Math.round(420 * timeScale)

    function clamp01(v) { return Math.max(0, Math.min(1, v)) }
    function lerp(a, b, t) { return a + (b - a) * t }

    function back(t) {
        const u = clamp01(t) - 1
        return 1 + 2.25 * u * u * u + 1.25 * u * u
    }

    function stagger(t, i, step) {
        const d = Math.min(0.5, i * (step === undefined ? 0.05 : step))
        return clamp01((t - d) / 0.5)
    }
}