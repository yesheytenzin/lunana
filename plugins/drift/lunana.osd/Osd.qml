import QtQuick
import Quickshell
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/onScreenDisplay" as LnMod

// lunana.osd — Lunana exact drift on-screen-display host (volume/brightness/layout). (kind: service).
//
// Resident host for lunana's exact OnScreenDisplay (modules/onScreenDisplay); it shows itself on the
// vendored tree's own state. No toggle: summoned only through the family
// switcher or not at all (see PORTING.md).
LnMod.OnScreenDisplay {

    // Shell-entry handshake in this plugin's singleton universe (each
    // installed plugin carries its own vendor/ copy, hence its own
    // GlobalStates): the vendored tree gates first paint on
    // shellEntryReady/deferredPanelsReady, which only lunana's shell.qml boot
    // sets. Mirror the minimal sequence here.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Lunana.GlobalStates.shellEntryReady = true;
            Lunana.GlobalStates.deferredPanelsReady = true;
        }
    }
}
