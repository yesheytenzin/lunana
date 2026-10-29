import "../../../.."
import "../../../common/widgets"
import "../../../common/functions"
import "../../../../services"
import "../../../../services/deferred"
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root
    
    name: Translation.tr("EasyEffects")

    toggled: EasyEffects.active
    buttonIcon: "graphic_eq"

    Component.onCompleted: {
        EasyEffects.fetchActiveState()
    }

    mainAction: () => {
        EasyEffects.toggle()
    }

    altAction: () => {
        ShellExec.execFishOrBashOneLiner(
            "flatpak run com.github.wwmm.easyeffects; or easyeffects",
            "/usr/bin/flatpak run com.github.wwmm.easyeffects || /usr/bin/easyeffects"
        )
        GlobalStates.sidebarRightOpen = false
    }

    StyledToolTip {
        text: Translation.tr("EasyEffects | Right-click to configure")
    }
}

