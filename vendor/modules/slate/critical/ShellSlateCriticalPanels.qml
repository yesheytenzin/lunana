pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../common"
import "../background" as SlateBackgroundModule
import "../bar" as SlateBarModule
import "../backdrop" as SlateBackdropModule

Item {
    id: root

    component CriticalPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready
            && (Config.options?.enabledPanels ?? []).includes(identifier)
            && extraCondition
    }

    CriticalPanelLoader {
        identifier: "slateBar"
        component: SlateBarModule.SlateBar {}
    }

    CriticalPanelLoader {
        identifier: "slateBackground"
        component: SlateBackgroundModule.SlateBackground {}
    }

    CriticalPanelLoader {
        identifier: "slateBackdrop"
        extraCondition: Config.options?.slate?.background?.backdrop?.enable ?? true
        component: SlateBackdropModule.SlateBackdrop {}
    }
}
