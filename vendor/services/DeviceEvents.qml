pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-C R5 load stub.
// Device-event bus for iRiS Island event toasts; live device events land
// with the device service unit.
Singleton {
    signal happened(event: var)
}
