import "../../../.."
import "../../../common"
import "../../../common/widgets"
import "../../../../services"
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Virtual Keyboard")
    toggled: GlobalStates.oskOpen
    buttonIcon: toggled ? "keyboard_hide" : "keyboard"
    
    mainAction: () => {
        GlobalStates.oskOpen = !GlobalStates.oskOpen
    }

    StyledToolTip {
        text: Translation.tr("On-screen keyboard")
    }
}
