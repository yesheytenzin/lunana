pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// LeftSidebarButton pings on AI answers; silent until the ai unit lands.
Singleton {
    signal responseFinished()
}
