import QtQuick
import Quickshell
import "vendor/modules/waffle/onScreenDisplay" as LnMod

// lunana.waffle-osd — Lunana Waffle OSD host. (kind: service).
//
// Resident host for inir's exact WaffleOSD (modules/waffle/onScreenDisplay); it shows itself on the
// vendored tree's own state. No toggle: summoned only through the family
// switcher or not at all (see PORTING.md).
LnMod.WaffleOSD {
}
