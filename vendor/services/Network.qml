pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// The exact ii bar reads wifi/ethernet state here; shows offline until the
// live-network unit backs this with NetworkManager.
Singleton {
    property var active: null
    property bool ethernet: false
    property string materialSymbol: ""
    property string networkName: ""
    property bool online: false
    property bool wifiEnabled: false
    function accessPointDetails(ap, full) { return ({}) }
    function refreshActiveNetworkDetails() {}
}
