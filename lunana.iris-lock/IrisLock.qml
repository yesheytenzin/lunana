import QtQuick
import Quickshell
import "vendor/modules/iris/lock" as LnMod

// lunana.iris-lock — Lunana iRiS lock host (dormant unless the iris family owns locking). (kind: service).
//
// Resident host for inir's exact IrisLockSurface (modules/iris/lock); it shows itself on the
// vendored tree's own state. No toggle: summoned only through the family
// switcher or not at all (see PORTING.md).
LnMod.IrisLockSurface {
}
