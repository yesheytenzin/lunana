import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "../../common/functions"
import "../looks"

SText {
    Layout.leftMargin: 12
    Layout.rightMargin: 12
    Layout.topMargin: 6
    Layout.bottomMargin: 6
    
    font {
        weight: Looks.font.weight.stronger
        pixelSize: Looks.font.pixelSize.large
    }
}
