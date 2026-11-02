pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import "../../../common"
import "../../looks"
import ".."

SSettingsPage {
    id: root

    settingsPageIndex: 17
    pageTitle: Translation.tr("Shell Layout")
    pageIcon: "desktop"
    pageDescription: Translation.tr("Move persistent Slate surfaces live or from Settings")

    readonly property var taskbarState: ShellLayoutController.currentState(
        "slateBar", "")

    function openLiveEditor(): void {
        Quickshell.execDetached([
            ((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")),
            "shellLayout",
            "open"
        ])
        Qt.quit()
    }

    SSettingsCard {
        title: Translation.tr("Live shell layout")
        icon: "desktop"

        SSettingsButton {
            label: Translation.tr("Edit live")
            icon: "drag_pan"
            description: Translation.tr("Show the real taskbar and placement targets on the desktop")
            buttonText: Translation.tr("Open editor")
            onButtonClicked: root.openLiveEditor()
        }
    }

    SSettingsCard {
        title: Translation.tr("Taskbar placement")
        icon: "desktop"

        SSettingsButton {
            label: Translation.tr("Current position")
            icon: "desktop"
            description: Translation.tr("Applies to every output enabled for the Slate taskbar")
            buttonText: Translation.tr(root.taskbarState?.slot ?? "bottom")
            onButtonClicked: {
                const target = (root.taskbarState?.slot ?? "bottom") === "bottom"
                    ? "top" : "bottom"
                ShellLayoutController.moveSurface("slateBar", target, "")
            }
        }

        SSettingsButton {
            label: Translation.tr("Reset placement")
            icon: "arrow-sync"
            description: Translation.tr("Restore the Slate taskbar to the bottom edge")
            buttonText: Translation.tr("Reset")
            onButtonClicked: ShellLayoutController.resetSurface("slateBar", "")
        }
    }
}
