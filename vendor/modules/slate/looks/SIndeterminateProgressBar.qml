import QtQuick
import Qt5Compat.GraphicalEffects
import "../../.."
import "../../common"
import "../../common/widgets"
import "."

StyledIndeterminateProgressBar {
    id: progressBar
    implicitHeight: 3
    background: null
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: progressBar.width
            height: progressBar.height
            radius: progressBar.height / 2
        }
    }
}
