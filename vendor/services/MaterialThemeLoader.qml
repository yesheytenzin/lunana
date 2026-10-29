pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — THE COLOR SEAM.
// inir's real MaterialThemeLoader reads colors.json and writes each key into
// Appearance.m3colors. This is the single injection point the plan targets: a
// later step feeds Omarchy's active palette into Appearance.m3colors here, and
// the whole Appearance -> widgets cascade inherits it. For now it satisfies
// Appearance's setDarkMode() call; Appearance's built-in default m3colors renders
// until the Omarchy-palette bridge is wired in.
Singleton {
    property bool darkMode: true
    function setDarkMode(mode) { darkMode = mode }
}
