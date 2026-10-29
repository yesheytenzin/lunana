pragma ComponentBehavior: Bound

import QtQuick
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../style"
import "../../components"

// The recording mark, breathing (IrisPulse).
IrisPulse {
    implicitWidth: 9 * IrisStyle.density
    implicitHeight: implicitWidth
    color: IrisStyle.danger
}
