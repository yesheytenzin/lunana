import QtQuick
import QtQuick.Layouts
import "../../services"
import "../common"
import "../common/widgets"
import "../sidebarRight/notepad"

/**
 * Quick notes card. Reuses the sidebar notepad (tabs, autosave to the shared
 * notepad state) so notes stay in sync across surfaces. Fills column height.
 */
DashCard {
    id: root
    title: Translation.tr("Notes")
    icon: "edit_note"
    Layout.fillHeight: true

    NotepadWidget {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 180
    }
}
