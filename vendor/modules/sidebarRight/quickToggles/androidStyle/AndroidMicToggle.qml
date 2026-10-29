import "../../../.."
import "../../../common"
import "../../../common/widgets"
import "../../../../services"
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Audio input")
    statusText: toggled ? Translation.tr("Enabled") : Translation.tr("Muted")
    toggled: !Audio.micMuted
    buttonIcon: Audio.micMuted ? "mic_off" : "mic"
    mainAction: () => {
        Audio.toggleMicMute()
    }

    altAction: () => {
        root.openMenu()
    }

    StyledToolTip {
        text: Translation.tr("Audio input | Right-click for volume mixer & device selector")
    }
}
