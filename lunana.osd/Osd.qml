import QtQuick
import Quickshell
import "vendor/modules/onScreenDisplay" as LnMod

// lunana.osd — Lunana exact ii on-screen-display host (volume/brightness/layout). (kind: service).
//
// Resident host for inir's exact OnScreenDisplay (modules/onScreenDisplay); it shows itself on the
// vendored tree's own state. No toggle: summoned only through the family
// switcher or not at all (see PORTING.md).
LnMod.OnScreenDisplay {
}
