import QtQuick
import Quickshell
import "vendor/modules/waffle/lock" as LnMod

// lunana.waffle-lock — Lunana Waffle lock host (dormant unless the waffle family owns locking). (kind: service).
//
// Resident host for inir's exact WaffleLockSurface (modules/waffle/lock); it shows itself on the
// vendored tree's own state. No toggle: summoned only through the family
// switcher or not at all (see PORTING.md).
LnMod.WaffleLockSurface {
}
