import "../../../.."
import "../../../common"
import "../../../common/widgets"
import "../../../../services"
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Screen snip")
    statusText: ""
    toggled: false
    buttonIcon: "screenshot_region"

    mainAction: () => {
        GlobalStates.sidebarRightOpen = false;
        delayedActionTimer.start()
    }
    Timer {
        id: delayedActionTimer
        interval: 300
        repeat: false
        onTriggered: {
            Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "region", "screenshot"])
        }
    }

    StyledToolTip {
        text: Translation.tr("Screen snip")
    }
}
