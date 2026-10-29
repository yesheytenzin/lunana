import QtQuick
import Quickshell
import "vendor/" as Inir
import "vendor/modules/iris/dock" as LnMod

// lunana.iris-dock — Lunana iRiS dock host (iris family only; ii dock yields while enabled). (kind: service).
//
// Resident host for inir's exact IrisDock (modules/iris/dock); it shows itself on the
// vendored tree's own state. No toggle: summoned only through the family
// switcher or not at all (see PORTING.md).
LnMod.IrisDock {

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
