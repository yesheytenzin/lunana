pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../common"
import "../looks"

// Switch setting row - Slate style
SSettingsRow {
    id: root
    
    property bool checked: false
    
    clickable: true
    onClicked: root.checked = !root.checked
    
    control: Component {
        SSwitch {
            checked: root.checked
            onClicked: root.checked = !root.checked
        }
    }
}
