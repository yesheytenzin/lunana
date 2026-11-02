import QtQuick
import Quickshell
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/atoll/background" as LnMod

// lunana.atoll-background — Lunana Atoll background/afterglow host. (kind: service).
//
// Resident host for lunana's exact AtollBackground (modules/atoll/background); it shows itself on the
// vendored tree's own state. No toggle: summoned only through the family
// switcher or not at all (see PORTING.md).
//
// Scope wrapper: AtollBackground's root is a bare Variants, whose default
// property is its delegate. A child declared here would replace the vendored
// PanelWindow delegate, so the handshake Timer lives beside the Variants in
// this Scope rather than inside it (same shape as the drift Background host).
Scope {
    id: root

    LnMod.AtollBackground {}

    // Shell-entry handshake against the shared lunana-vendor/ tree (one
    // GlobalStates universe for all hosts): the vendored tree gates first paint on
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
