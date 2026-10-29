import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "../../common/models"
import "../../common/functions"
import "../../common/widgets"
import "../looks"

Item {
    id: root
    property var entry
    property int iconSize: Config.options?.waffles?.bar?.searchIconSize ?? 24
    implicitWidth: Math.max(iconSize, textIconLoader.implicitWidth)
    implicitHeight: iconSize
    
    Loader {
        anchors.centerIn: parent
        active: (root.entry?.iconType === LauncherSearchResult.IconType.System) && (root.entry?.iconName ?? "") !== ""
        sourceComponent: WAppIcon {
            implicitSize: root.iconSize
            iconName: root.entry?.iconName ?? ""
            tryCustomIcon: false
        }
    }
    
    Loader {
        id: textIconLoader
        anchors.centerIn: parent
        active: root.entry?.iconType === LauncherSearchResult.IconType.Text
        sourceComponent: WText {
            text: root.entry?.iconName ?? ""
            font.pixelSize: root.iconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    
    Loader {
        anchors.centerIn: parent
        active: (root.entry?.iconType === LauncherSearchResult.IconType.Material)
            || (root.entry?.iconType === LauncherSearchResult.IconType.None)
            || ((root.entry?.iconName ?? "") === "")
        sourceComponent: FluentIcon {
            icon: (root.entry?.iconName ?? "") !== ""
                ? WIcons.fluentFromMaterial(root.entry?.iconName ?? "")
                : WIcons.guessIconForName(root.entry?.name ?? "")
            implicitSize: root.iconSize
        }
    }
}
