import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/atoll/sidebar" as LnMod

// lunana.atoll-sidebar-right — Atoll "today" sidebar host (kind: overlay).
//
// Mirror of lunana.atoll-sidebar-left for side "right": AtollSidebar is a
// layershell PanelWindow targeting GlobalStates.sidebarRightTargetOutput (set
// by openSidebarRight). The host binds its screen to that output and drives
// open/close through the vendored helpers.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Lunana.GlobalStates.sidebarRightOpen

  function open(payloadJson) { Lunana.GlobalStates.openSidebarRight("") }
  function close() { Lunana.GlobalStates.closeSidebarRight() }
  function toggle() { Lunana.GlobalStates.toggleSidebarRight("") }

  ShellIpc {
    target: "lunana.atoll-sidebar-right"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.AtollSidebar {
    side: "right"
    screen: {
      const name = Lunana.GlobalStates.sidebarRightTargetOutput;
      const target = name ? Quickshell.screens.find(s => s.name === name) : null;
      return target ?? Lunana.GlobalStates.focusedScreen
        ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
    }
  }

  Timer {
    interval: 200; repeat: false; running: true
    onTriggered: {
      Lunana.GlobalStates.shellEntryReady = true;
      Lunana.GlobalStates.deferredPanelsReady = true;
    }
  }
}
