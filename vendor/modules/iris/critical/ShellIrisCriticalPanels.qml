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
        active: Config.ready && IrisGate.official
            && (Config.options?.enabledPanels ?? []).includes(identifier)
            && extraCondition
    }

    CriticalPanelLoader {
        identifier: "irisBackground"
        extraCondition: !(Config.options?.iris?.modules?.desktopWidgets ?? true)
        component: IrisBackground {}
    }

    LazyLoader {
        active: Config.ready && IrisGate.official
        component: IrisReservations {}
    }

    CriticalPanelLoader {
        identifier: "irisBar"
        component: IrisBar {}
    }
}
