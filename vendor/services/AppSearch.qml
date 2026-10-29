pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A 2a load stub.
// Desktop-entry resolution for the ii dock's pinned/running buttons. Null-safe
// callers (`?.`) render fallback icons until this is backed by
// Quickshell.Services.DesktopEntries in the live-windows unit.
Singleton {
    function guessIcon(appId) { return "" }
    function getIconSource(appId, fallback) { return "" }
    function lookupDesktopEntry(appId) { return null }
    function resolveWindowIdentity(toplevel) { return null }
    function launchEntry(entry) {}
    function launchDesktopAction(desktopEntry, action) {}
}
