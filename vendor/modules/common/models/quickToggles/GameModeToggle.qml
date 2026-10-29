import QtQuick
import "../../../../services"
import "../.."

QuickToggleModel {
    name: Translation.tr("Game mode")
    toggled: GameMode.active
    icon: "gamepad"
    mainAction: () => GameMode.toggle()
    tooltipText: Translation.tr("Game mode")
}
