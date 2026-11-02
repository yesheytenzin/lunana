import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../.."
import "../../../services"
import "../../../services/deferred"
import "../../common"
import "../looks"

AppButton {
    id: root

    iconName: checked ? "system-search-checked" : "system-search"
    separateLightDark: true

    checked: GlobalStates.searchOpen && LauncherSearch.query !== ""
    onClicked: {
        GlobalStates.searchOpen = !GlobalStates.searchOpen
    }

    BarToolTip {
        id: tooltip
        text: Translation.tr("Search")
        barExtraVisibleCondition: root.shouldShowTooltip
    }
}
