import "../../../common/widgets"
import "../../../common/functions"
import "../../../.."
import "../../../../services"
import "../../../../services/deferred"
import QtQuick
import Quickshell.Io
import Quickshell

QuickToggleButton {
    id: root
    visible: EasyEffects.available
    toggled: EasyEffects.active
    buttonIcon: "instant_mix"

    Component.onCompleted: {
        EasyEffects.fetchActiveState()
    }

    onClicked: {
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
