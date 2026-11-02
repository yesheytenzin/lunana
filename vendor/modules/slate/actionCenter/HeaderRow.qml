import QtQuick
import QtQuick.Layouts
import Quickshell
import "../looks"
import "."

RowLayout {
    id: root

    required property string title
    spacing: 4

    SPanelIconButton {
        iconName: "arrow-left"
        onClicked: ActionCenterContext.back()
    }

    SText {
        id: titleText
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: root.title
        font.pixelSize: Looks.font.pixelSize.large
    }
}
