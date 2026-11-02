pragma ComponentBehavior: Bound
import "../../../services"
import "../../common"
import "../../common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "crosshair"
import "volumeMixer"
import "floatingImage"
import "fpsLimiter"
import "recorder"
import "resources"
import "gamePerformance"
import "notes"
import "discord"
import "notifications"

DelegateChooser {
    id: root
    role: "identifier"

    DelegateChoice { roleValue: "crosshair"; Crosshair {} }
    DelegateChoice { roleValue: "floatingImage"; FloatingImage {} }
    DelegateChoice { roleValue: "fpsLimiter"; FpsLimiter {} }
    DelegateChoice { roleValue: "recorder"; Recorder {} }
    DelegateChoice { roleValue: "resources"; Resources {} }
    DelegateChoice { roleValue: "gamePerformance"; GamePerformance {} }
    DelegateChoice { roleValue: "notes"; Notes {} }
    DelegateChoice { roleValue: "discord"; Discord {} }
    DelegateChoice { roleValue: "volumeMixer"; VolumeMixer {} }
    DelegateChoice { roleValue: "notifications"; Notifications {} }
}
