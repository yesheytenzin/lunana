import "../../../.."
import "../../../common"
import "../../../common/functions"
import "../../../common/widgets"
import "../../../../services"
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Color picker")
    statusText: ""
    toggled: false
    buttonIcon: "colorize"

    mainAction: () => {
        GlobalStates.sidebarRightOpen = false;
        delayedActionTimer.start()
    }
    Timer {
        id: delayedActionTimer
        interval: 300
        repeat: false 
        onTriggered: {
            ShellExec.execDetachedArgs(["/usr/bin/hyprpicker", "-a"], "Pick color")
        }
    }

    StyledToolTip {
        text: Translation.tr("Color picker")
    }
}
