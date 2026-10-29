pragma Singleton
import QtQuick
import Quickshell
// LUNANA SHIM — inir's per-output wallpaper URL provider (used by glass widgets).
Singleton {
    function wallpaperUrlForScreen(screen) { return "" }
}
