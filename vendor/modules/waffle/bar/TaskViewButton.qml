import QtQuick
import QtQuick.Layouts
import Quickshell
import org.kde.kirigami as Kirigami
import "../../.."
import "../../../services"
import "../../common"
import "../looks"

AppButton {
    id: root

    iconName: (down && !checked) ? "task-view-pressed" : "task-view"
    pressedScale: checked ? 5/6 : 1
    separateLightDark: true

    checked: GlobalStates.waffleTaskViewOpen
    onClicked: {
        // Use IPC to toggle TaskView - this triggers preview capture before opening
        Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/inir")), "taskview", "toggle"])
    }

    BarToolTip {
        barExtraVisibleCondition: root.shouldShowTooltip
        text: Translation.tr("Task View")
    }
}
