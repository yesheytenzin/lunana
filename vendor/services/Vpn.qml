pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-C R5 load stub.
// The iRiS pieces registry reads `available` for the vpn slot; live VPN
// state lands with the network service unit.
Singleton {
    property bool available: false
}
