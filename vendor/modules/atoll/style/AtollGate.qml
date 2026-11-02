pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Atoll surfaces open only when the host shell is Lunana: its own shell.qml loads
// ShellIrisPanels.qml. A host that embeds the module under a different
// shell.qml keeps them closed.
QtObject {
    id: root

    readonly property bool official: hostFile.text().includes("ShellIrisPanels.qml")

    property FileView hostFile: FileView {
        path: ((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("shell.qml"))
        blockLoading: true
        printErrors: false
    }

    Component.onCompleted: {
        if (!root.official)
            console.warn("[AtollGate] Atoll only runs inside Lunana; this host is not Lunana, so its surfaces stay closed.")
    }
}
