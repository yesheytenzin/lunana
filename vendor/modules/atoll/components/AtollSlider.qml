import QtQuick
import "../../common/widgets"
import "../style"

Item {
    id: root

    property alias value: slider.value
    readonly property alias pressed: slider.pressed
    signal moved(real value)

    implicitWidth: 220
    implicitHeight: Math.round(34 * AtollStyle.density)

    StyledSlider {
        id: slider
        anchors.fill: parent
        enabled: root.enabled
        enableSettingsSearch: false
        configuration: StyledSlider.Configuration.XS
        trackWidth: 4
        trackRadius: 2
        handleHeight: 12
        handleDefaultWidth: 12
        handlePressedWidth: 14
        handleMargins: 0
        stopIndicatorValues: []
        highlightColor: AtollStyle.accent
        handleColor: AtollStyle.accent
        trackColor: AtollStyle.accentContainer
        dotColor: AtollStyle.subtext
        dotColorHighlighted: AtollStyle.inkOnAccentContainer
        scrollable: true
        onMoved: root.moved(slider.value)
    }
}
