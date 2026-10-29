import QtQuick
import "../../../../services"
import "../.."
import "../../functions"
import "../../widgets"

QuickToggleModel {
    name: Translation.tr("Anti-flashbang")
    tooltipText: Translation.tr("Anti-flashbang")
    icon: "flash_off"
    toggled: Config.options?.light?.antiFlashbang?.enable ?? false

    mainAction: () => {
        const current = Config.options?.light?.antiFlashbang?.enable ?? false
        Config.setNestedValue("light.antiFlashbang.enable", !current)
    }
    hasMenu: true
}
