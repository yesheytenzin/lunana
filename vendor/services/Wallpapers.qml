pragma Singleton
import QtQuick
import Quickshell
// LUNANA SHIM — inir's Wallpapers service. Appearance reads the current wallpaper
// path for its dominant-colour/vibrancy maths; lunana will later source this from
// Omarchy. Empty values are safe (Appearance falls back to m3colors).
Singleton {
    property string effectiveWallpaperPath: ""
    function stillUrlFor(path) { return "" }
}
