pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/wallpaper" as LnWall

// iRiS wallpaper gallery. Gated on GlobalStates.wallpaperSelectorOpen.
Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            required property var modelData
            readonly property bool shown: Inir.GlobalStates.wallpaperSelectorOpen
            screen: modelData
            visible: shown
            color: "transparent"
            WlrLayershell.namespace: "lunana-iris-wallpaper"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }
            MouseArea { anchors.fill: parent; onClicked: Inir.GlobalStates.wallpaperSelectorOpen = false }
            Item { anchors.fill: parent; focus: parent.shown; Keys.onEscapePressed: Inir.GlobalStates.wallpaperSelectorOpen = false }
            Loader {
                anchors.fill: parent
                active: parent.shown
                sourceComponent: Component {
                    LnWall.IrisWallpaperPicker {
                        screen: modelData
                    }
                }
            }
        }
    }
}
