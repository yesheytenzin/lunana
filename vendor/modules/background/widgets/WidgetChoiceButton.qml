pragma ComponentBehavior: Bound

import QtQuick
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../../atoll/style"

SelectionGroupButton {
    id: root
    // Atoll: quiet translucent choices on black, the accent marks the selected one
    // (the same pairing as the edit toolbar's committing action).
    readonly property bool atoll: (Config.options?.panelFamily ?? "drift") === "atoll"
    implicitHeight: 32

    // Override the inherited family-aware bindings only while Atoll owns this
    // control. Restore them verbatim when the panel family changes at runtime.
    Binding { target: root; property: "colBackground"; value: ColorUtils.applyAlpha(AtollStyle.text, 0.08); when: root.atoll; restoreMode: Binding.RestoreBinding }
    Binding { target: root; property: "colBackgroundHover"; value: ColorUtils.applyAlpha(AtollStyle.text, 0.14); when: root.atoll; restoreMode: Binding.RestoreBinding }
    Binding { target: root; property: "colBackgroundActive"; value: ColorUtils.applyAlpha(AtollStyle.text, 0.2); when: root.atoll; restoreMode: Binding.RestoreBinding }
    Binding { target: root; property: "colBackgroundToggled"; value: AtollStyle.accent; when: root.atoll; restoreMode: Binding.RestoreBinding }
    Binding { target: root; property: "colBackgroundToggledHover"; value: Qt.lighter(AtollStyle.accent, 1.08); when: root.atoll; restoreMode: Binding.RestoreBinding }
    StyledToolTip { text: root.buttonText }
}
