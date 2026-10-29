import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import "../../../common"
import "../../../common/functions"
import "../../looks"
import ".."

ActionCenterToggle {
    id: root

    name: Network.ethernet ? Translation.tr("Network") : Network.networkName


}
