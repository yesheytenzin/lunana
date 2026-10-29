pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// The exact ii bar resolves a per-screen brightness monitor for scroll-to-
// adjust; null until the live-brightness unit backs this with ddcutil.
Singleton {
    function getMonitorForScreen(screen) { return null }
}
