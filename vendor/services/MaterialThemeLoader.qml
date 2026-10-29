pragma Singleton
import QtQuick
import Quickshell
import qs.Commons as Oc
import "../modules/common" as LnCommon
import "../modules/common/functions"

// LUNANA SHIM (not vendored from inir) — THE COLOR SEAM.
// inir's real MaterialThemeLoader reads colors.json and assigns each key into
// Appearance.m3colors. lunana feeds Omarchy's live palette instead: every key
// Omarchy owns (foreground/background/accent/urgent/muted) is derived below,
// so the whole Appearance -> Looks/IrisStyle/widgets cascade inherits Omarchy
// colors while keeping inir's exact shapes. Terminal (term*), success and
// *-fixed keys keep inir defaults — out of scope until a terminal surface lands.
Singleton {
    id: root

    property bool darkMode: true

    function setDarkMode(mode) {
        darkMode = !!mode
        applyPalette()
    }

    function inkOn(c) {
        return c.hslLightness < 0.5 ? Qt.lighter(c, 2.2) : Qt.darker(c, 2.2)
    }

    // Polarity-aware ladder rung: mix bg toward the dark pole (fg on light
    // themes, black on dark themes) or toward the light pole (fg on dark
    // themes, white on light themes). Linear mixes never clip the way
    // Qt.darker/lighter do near white, so both poles keep distinct rungs.

    function applyPalette() {
        const m3 = LnCommon.Appearance?.m3colors
        if (!m3)
            return
        const bg = Oc.Color.background
        const fg = Oc.Color.foreground
        const ac = Oc.Color.accent
        const ug = Oc.Color.urgent
        const mu = Oc.Color.muted
        const dark = bg.hslLightness < 0.5
        root.darkMode = dark
        m3.darkmode = dark

        // Base surfaces ladder off the background.
        const lowPole = dark ? "#000000" : fg
        const highPole = dark ? fg : "#ffffff"
        m3.m3background = bg
        m3.m3onBackground = fg
        m3.m3surface = bg
        m3.m3surfaceDim = ColorUtils.mix(bg, lowPole, 0.8)
        m3.m3surfaceBright = ColorUtils.mix(bg, highPole, 0.92)
        m3.m3surfaceContainerLowest = ColorUtils.mix(bg, lowPole, 0.72)
        m3.m3surfaceContainerLow = ColorUtils.mix(bg, lowPole, 0.88)
        m3.m3surfaceContainer = bg
        m3.m3surfaceContainerHigh = ColorUtils.mix(bg, highPole, 0.85)
        m3.m3surfaceContainerHighest = ColorUtils.mix(bg, highPole, 0.78)
        m3.m3onSurface = fg
        m3.m3surfaceVariant = ColorUtils.mix(bg, fg, 0.75)
        m3.m3onSurfaceVariant = mu
        m3.m3inverseSurface = fg
        m3.m3inverseOnSurface = bg
        m3.m3outline = mu
        m3.m3outlineVariant = ColorUtils.mix(mu, bg, 0.6)
        m3.m3shadow = "#000000"
        m3.m3scrim = "#000000"
        m3.m3surfaceTint = ac

        // Accent roles.
        m3.m3primary = ac
        m3.m3onPrimary = root.inkOn(ac)
        m3.m3primaryContainer = dark ? Qt.darker(ac, 1.6) : Qt.lighter(ac, 1.3)
        m3.m3onPrimaryContainer = dark ? Qt.lighter(ac, 1.6) : Qt.darker(ac, 1.6)
        m3.m3inversePrimary = dark ? Qt.lighter(ac, 1.4) : Qt.darker(ac, 1.4)
        m3.m3secondary = mu
        m3.m3onSecondary = root.inkOn(mu)
        m3.m3secondaryContainer = dark ? Qt.darker(mu, 1.6) : Qt.lighter(mu, 1.3)
        m3.m3onSecondaryContainer = dark ? Qt.lighter(mu, 1.6) : Qt.darker(mu, 1.6)
        const te = dark ? Qt.lighter(ac, 1.4) : Qt.darker(ac, 1.2)
        m3.m3tertiary = te
        m3.m3onTertiary = root.inkOn(te)
        m3.m3tertiaryContainer = dark ? Qt.darker(te, 1.5) : Qt.lighter(te, 1.2)
        m3.m3onTertiaryContainer = dark ? Qt.lighter(te, 1.5) : Qt.darker(te, 1.5)

        // Error roles from urgent.
        m3.m3error = ug
        m3.m3onError = root.inkOn(ug)
        m3.m3errorContainer = dark ? Qt.darker(ug, 1.6) : Qt.lighter(ug, 1.3)
        m3.m3onErrorContainer = dark ? Qt.lighter(ug, 1.6) : Qt.darker(ug, 1.6)
    }

    Component.onCompleted: applyPalette()

    Connections {
        target: Oc.Color
        function onBackgroundChanged() { root.applyPalette() }
        function onForegroundChanged() { root.applyPalette() }
        function onAccentChanged() { root.applyPalette() }
        function onUrgentChanged() { root.applyPalette() }
        function onMutedChanged() { root.applyPalette() }
        function onShellValuesChanged() { root.applyPalette() }
    }
}
