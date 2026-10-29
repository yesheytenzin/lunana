import QtQuick
import Quickshell
import "vendor/modules/bar" as LnBar

// lunana.bar — exact ii bar host (kind: bar).
//
// Full cutover: the M0-M4 approximation is gone. This entry point mounts inir's
// exact bar Scope (vendored) directly; the suite materializes its
// import-closure subset under the installed plugin's vendor/ (see
// lunana-suite VENDOR_ROOTS). Selected via shell.json -> bar.id = "lunana.bar".
LnBar.Bar {
}
