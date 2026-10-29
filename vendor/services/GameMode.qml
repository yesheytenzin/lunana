pragma Singleton
import QtQuick
import Quickshell
// LUNANA SHIM — inir's GameMode (disables effects in fullscreen games).
Singleton {
    property bool enabled: false
    property bool active: false
    // inir parity: the person toggling game mode by hand. Never set until
    // the manual toggle unit lands; the island only reads it for its toast.
    property bool manuallyActivated: false
}
