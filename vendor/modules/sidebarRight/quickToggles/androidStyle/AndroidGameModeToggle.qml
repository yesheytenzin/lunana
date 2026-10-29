import QtQuick
import "../../../common"
import "../../../common/widgets"
import "../../../../services"

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Game mode")
    statusText: GameMode.active ? Translation.tr("Active") : ""
    toggled: GameMode.active
    buttonIcon: "gamepad"

    mainAction: () => {
        GameMode.toggle()
    }

    StyledToolTip {
        text: GameMode.active 
            ? Translation.tr("Game mode") + " (" + (GameMode.manuallyActivated ? Translation.tr("manual") : Translation.tr("auto")) + ")"
            : Translation.tr("Game mode")
    }
}
