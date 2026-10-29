import QtQuick
import QtQuick.Layouts
import "../../.."
import "../../../services"
import "../../common"
import "../looks"

AppButton {
    id: root

    readonly property bool expandedForm: Config.options?.waffles?.bar?.leftAlignApps ?? false
    leftInset: expandedForm ? 0 : 12
    implicitWidth: expandedForm ? 148 : (height - topInset - bottomInset + leftInset + rightInset)
    iconName: "widgets"

    checked: GlobalStates.waffleWidgetsOpen
    onClicked: GlobalStates.waffleWidgetsOpen = !GlobalStates.waffleWidgetsOpen

    BarToolTip {
        barExtraVisibleCondition: root.shouldShowTooltip
        text: Translation.tr("Widgets")
    }
}
