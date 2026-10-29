import QtQuick
import Quickshell
import "vendor/modules/dock" as LnDock

// lunana.dock — exact ii dock host (kind: service).
//
// Full cutover: the M2 approximation is gone. This entry point mounts inir's
// exact dock Scope (vendored) directly; the suite materializes its
// import-closure subset under the installed plugin's vendor/.
LnDock.Dock {
}
