pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/sidebar" as LnSidebar

// iRiS focus (left) + today (right) side panels. Each is a layershell window
// that self-gates on GlobalStates.sidebarLeftOpen/RightOpen, which the island's
// focus/today buttons set in this same plugin's GlobalStates. Screen tracks the
// target output the open helper resolved.
Scope {
    id: root

    LnSidebar.IrisSidebar {
        side: "left"
        screen: {
            const name = Inir.GlobalStates.sidebarLeftTargetOutput;
            const target = name ? Quickshell.screens.find(s => s.name === name) : null;
            return target ?? Inir.GlobalStates.focusedScreen
                ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
        }
    }

    LnSidebar.IrisSidebar {
        side: "right"
        screen: {
            const name = Inir.GlobalStates.sidebarRightTargetOutput;
            const target = name ? Quickshell.screens.find(s => s.name === name) : null;
            return target ?? Inir.GlobalStates.focusedScreen
                ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
        }
    }
}
