import "../../../common/widgets"
import "../../../../services"

QuickToggleButton {
    toggled: Idle.inhibit
    buttonIcon: "coffee"
    onClicked: Idle.toggleInhibit()
    StyledToolTip { text: Translation.tr("Keep system awake") }
}
