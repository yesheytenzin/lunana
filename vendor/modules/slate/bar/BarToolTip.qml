import QtQuick
import Quickshell
import "../../.."
import "../../common"
import "../looks"

SPopupToolTip {
    id: root

    anchorEdges: (Config.options?.slate?.bar?.bottom ?? false) ? Edges.Top : Edges.Bottom

    readonly property bool _anyPanelOpen: GlobalStates.searchOpen
        || GlobalStates.slateActionCenterOpen
        || GlobalStates.slateNotificationCenterOpen
        || GlobalStates.slateWidgetsOpen
        || GlobalStates.slateAltSwitcherOpen
        || GlobalStates.slateClipboardOpen
        || GlobalStates.slateTaskViewOpen

    property bool barExtraVisibleCondition: true
    extraVisibleCondition: root.barExtraVisibleCondition && !root._anyPanelOpen
}
