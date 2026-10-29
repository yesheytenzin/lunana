pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// LeftSidebarButton pings on wallhaven answers; silent until the unit lands.
Singleton {
    signal responseFinished()
    signal tagSuggestion(string query, var suggestions)
}
