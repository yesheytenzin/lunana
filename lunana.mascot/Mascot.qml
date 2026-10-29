import QtQuick
import Quickshell
import "../lunana-vendor/" as Inir
import "../lunana-vendor/modules/mascot" as LnMod

// lunana.mascot — Lunana exact ii mascot host. (kind: service).
//
// Resident host for inir's exact MascotCompanion (modules/mascot); it shows itself on the
// vendored tree's own state. No toggle: summoned only through the family
// switcher or not at all (see PORTING.md).
LnMod.MascotCompanion {

    // Shell-entry handshake in this plugin's singleton universe (each
    // installed plugin carries its own vendor/ copy, hence its own
    // GlobalStates): the vendored tree gates first paint on
    // shellEntryReady/deferredPanelsReady, which only inir's shell.qml boot
    // sets. Mirror the minimal sequence here.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Inir.GlobalStates.shellEntryReady = true;
            Inir.GlobalStates.deferredPanelsReady = true;
        }
    }
}
