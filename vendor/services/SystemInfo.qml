pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-C load stub.
// inir's real SystemInfo collects distro/username/display-name via helper
// processes. The iRiS core closure only reads `username` (avatar path in
// Directories); the collectors land with the session unit.
Singleton {
    property string username: Quickshell.env("USER") || "user"
}
