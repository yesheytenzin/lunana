
import "../../../../../services"
import "../../../../common"
import "../../../../common/widgets"
import QtQuick

Rectangle {
    id: rect
    readonly property string dialStyle: Config.getNestedValue("background.widgets.clock.cookie.dialNumberStyle", "full")

    StyledText {
        anchors.centerIn: parent
        color: Appearance.colors.colSecondaryHover
        text: Qt.locale().toString(DateTime.clock.date, "dd")
        font {
            family: Config.getNestedValue("background.widgets.clock.fontFamily", "Space Grotesk")
            pixelSize: 20
            weight: 1000
        }
    }
}
