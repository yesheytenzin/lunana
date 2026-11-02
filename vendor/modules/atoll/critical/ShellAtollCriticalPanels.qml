pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../common"
import "../background"
import "../bar"
import "../frame"
import "../style"

Item {
    id: root

    component CriticalPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && AtollGate.official
            && (Config.options?.enabledPanels ?? []).includes(identifier)
            && extraCondition
    }

    CriticalPanelLoader {
        identifier: "atollBackground"
        extraCondition: !(Config.options?.atoll?.modules?.desktopWidgets ?? true)
        component: AtollBackground {}
    }

    LazyLoader {
        active: Config.ready && AtollGate.official
        component: AtollReservations {}
    }

    CriticalPanelLoader {
        identifier: "atollBar"
        component: AtollBar {}
    }
}
