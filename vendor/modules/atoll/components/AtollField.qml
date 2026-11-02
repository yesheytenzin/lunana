pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../../common"
import "../../common/widgets"
import "../style"

MaterialTextField {
    id: root

    enableSettingsSearch: false
    color: AtollStyle.text
    placeholderTextColor: "transparent"
    selectionColor: AtollStyle.accentContainer
    selectedTextColor: AtollStyle.inkOnAccentContainer
    font.family: AtollStyle.fontTitle
    font.pixelSize: AtollStyle.typeHeadline
    leftPadding: 14 * AtollStyle.density
    rightPadding: 14 * AtollStyle.density
    // Material insets the background for a floating label Atoll never shows, which drops the box below its text.
    topInset: 0
    bottomInset: 0

    AtollText {
        anchors.left: parent.left
        anchors.leftMargin: root.leftPadding
        anchors.right: parent.right
        anchors.rightMargin: root.rightPadding
        anchors.verticalCenter: parent.verticalCenter
        visible: root.text.length === 0 && root.placeholderText.length > 0
        text: root.placeholderText
        font.family: root.font.family
        font.pixelSize: root.font.pixelSize
        color: AtollStyle.subtext
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: AtollStyle.radiusSmall
        color: AtollStyle.field
        border.width: root.activeFocus ? 1 : 0
        border.color: AtollStyle.hairlineStrong
    }
}
