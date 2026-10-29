pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../common"
import "../looks"

// Switch setting row - Windows 11 style
WSettingsRow {
    id: root
    
    property bool checked: false
    
    clickable: true
    onClicked: root.checked = !root.checked
    
    control: Component {
        WSwitch {
            checked: root.checked
            onClicked: root.checked = !root.checked
        }
    }
}
