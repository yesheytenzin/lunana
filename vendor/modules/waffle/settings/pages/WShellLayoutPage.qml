pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import "../../../common"
import "../../looks"
import ".."

WSettingsPage {
    id: root

    settingsPageIndex: 17
    pageTitle: Translation.tr("Shell Layout")
    pageIcon: "desktop"
    pageDescription: Translation.tr("Move persistent Waffle surfaces live or from Settings")

    readonly property var taskbarState: ShellLayoutController.currentState(
        "waffleBar", "")

    function openLiveEditor(): void {
        Quickshell.execDetached([
            ((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/inir")),
            "shellLayout",
            "open"
        ])
        Qt.quit()
    }

    WSettingsCard {
        title: Translation.tr("Live shell layout")
        icon: "desktop"

        WSettingsButton {
            label: Translation.tr("Edit live")
            icon: "drag_pan"
            description: Translation.tr("Show the real taskbar and placement targets on the desktop")
            buttonText: Translation.tr("Open editor")
            onButtonClicked: root.openLiveEditor()
        }
    }

    WSettingsCard {
        title: Translation.tr("Taskbar placement")
        icon: "desktop"

        WSettingsButton {
            label: Translation.tr("Current position")
            icon: "desktop"
            description: Translation.tr("Applies to every output enabled for the Waffle taskbar")
            buttonText: Translation.tr(root.taskbarState?.slot ?? "bottom")
            onButtonClicked: {
                const target = (root.taskbarState?.slot ?? "bottom") === "bottom"
                    ? "top" : "bottom"
                ShellLayoutController.moveSurface("waffleBar", target, "")
            }
        }

        WSettingsButton {
            label: Translation.tr("Reset placement")
            icon: "arrow-sync"
            description: Translation.tr("Restore the Waffle taskbar to the bottom edge")
            buttonText: Translation.tr("Reset")
            onButtonClicked: ShellLayoutController.resetSurface("waffleBar", "")
        }
    }
}
