import QtQuick
import Quickshell
import "vendor/modules/iris/dock" as LnMod

// lunana.iris-dock — Lunana iRiS dock host (iris family only; ii dock yields while enabled). (kind: service).
//
// Resident host for inir's exact IrisDock (modules/iris/dock); it shows itself on the
// vendored tree's own state. No toggle: summoned only through the family
// switcher or not at all (see PORTING.md).
LnMod.IrisDock {
}
