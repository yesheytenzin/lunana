pragma ComponentBehavior: Bound

import QtQuick
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../style"
import "../../components"

// The recording mark, breathing (AtollPulse).
AtollPulse {
    implicitWidth: 9 * AtollStyle.density
    implicitHeight: implicitWidth
    color: AtollStyle.danger
}
