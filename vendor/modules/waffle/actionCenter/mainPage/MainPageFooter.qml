import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../.."
import "../../../../services"
import "../../../common"
import "../../../common/functions"
import "../../looks"
import ".."

FooterRectangle {

    // Battery button
    WBorderlessButton {
        visible: Battery.available
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Looks.dp(12)

        contentItem: Row {
            spacing: Looks.dp(4)

            FluentIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: WIcons.batteryLevelIcon ?? "battery-0"
                FluentIcon {
                    anchors.fill: parent
                    icon: WIcons.batteryIcon ?? "battery-0"
                }
            }
            WText {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Math.round((Battery?.percentage ?? 0) * 100)}%`
            }
        }
    }

    // Settings button
    WBorderlessButton {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Looks.dp(12)

        onClicked: {
            GlobalStates.waffleActionCenterOpen = false;
            Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/inir")), "settings"]);
        }

        contentItem: FluentIcon {
            icon: "settings"
        }
    }
}
