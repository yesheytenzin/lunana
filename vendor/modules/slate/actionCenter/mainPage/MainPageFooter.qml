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
    SBorderlessButton {
        visible: Battery.available
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Looks.dp(12)

        contentItem: Row {
            spacing: Looks.dp(4)

            FluentIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: SIcons.batteryLevelIcon ?? "battery-0"
                FluentIcon {
                    anchors.fill: parent
                    icon: SIcons.batteryIcon ?? "battery-0"
                }
            }
            SText {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Math.round((Battery?.percentage ?? 0) * 100)}%`
            }
        }
    }

    // Settings button
    SBorderlessButton {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Looks.dp(12)

        onClicked: {
            GlobalStates.slateActionCenterOpen = false;
            Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")), "settings"]);
        }

        contentItem: FluentIcon {
            icon: "settings"
        }
    }
}
