import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/atoll/sidebar" as LnMod

// lunana.atoll-sidebar-left — Atoll "focus" sidebar host (kind: overlay).
//
// AtollSidebar is itself a layershell PanelWindow keyed to side + the vendored
// GlobalStates sidebar state; it targets one output (GlobalStates
// .sidebarLeftTargetOutput, set by openSidebarLeft). The host binds its screen
// to that output (falling back to the focused screen) and drives open/close
// through the vendored helpers, so the Atoll family keeps its focus panel while
// the drift lunana.sidebar-left stays stood down.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Lunana.GlobalStates.sidebarLeftOpen

  function open(payloadJson) { Lunana.GlobalStates.openSidebarLeft("") }
  function close() { Lunana.GlobalStates.closeSidebarLeft() }
  function toggle() { Lunana.GlobalStates.toggleSidebarLeft("") }

  ShellIpc {
    target: "lunana.atoll-sidebar-left"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.AtollSidebar {
    side: "left"
    screen: {
      const name = Lunana.GlobalStates.sidebarLeftTargetOutput;
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
