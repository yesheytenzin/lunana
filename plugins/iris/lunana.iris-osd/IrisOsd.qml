import QtQuick
import Quickshell
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/onScreenDisplay" as LnMod

// lunana.iris-osd — iRiS on-screen-display host (volume/brightness/layout). (kind: service).
//
// The iRiS counterpart of lunana.osd. IrisOSD self-windows on the vendored
// tree's own osd*Open state (GlobalStates.osdVolumeOpen/osdBrightnessOpen/…),
// so there is no toggle: it shows itself when the family's OSD fires. Enabled
// only while the iRiS family is active (family-cycle owns the set), so exactly
// one family's OSD is live at a time.
LnMod.IrisOSD {

    // Shell-entry handshake in this plugin's singleton universe: the vendored
    // tree gates first paint on shellEntryReady/deferredPanelsReady, which only
    // inir's shell.qml boot sets. Mirror the minimal sequence here.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Inir.GlobalStates.shellEntryReady = true;
            Inir.GlobalStates.deferredPanelsReady = true;
        }
    }
}
