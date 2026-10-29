pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// LeftSidebarButton pings on booru answers; silent until the booru unit lands.
Singleton {
    signal responseFinished()
    signal tagSuggestion(string query, var suggestions)
}
