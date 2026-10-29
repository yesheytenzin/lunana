import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/sidebar" as LnMod

// lunana.iris-sidebar-left — iRiS "focus" sidebar host (kind: overlay).
//
// IrisSidebar is itself a layershell PanelWindow keyed to side + the vendored
// GlobalStates sidebar state; it targets one output (GlobalStates
// .sidebarLeftTargetOutput, set by openSidebarLeft). The host binds its screen
// to that output (falling back to the focused screen) and drives open/close
// through the vendored helpers, so the iRiS family keeps its focus panel while
// the ii lunana.sidebar-left stays stood down.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.sidebarLeftOpen

  function open(payloadJson) { Inir.GlobalStates.openSidebarLeft("") }
  function close() { Inir.GlobalStates.closeSidebarLeft() }
  function toggle() { Inir.GlobalStates.toggleSidebarLeft("") }

  ShellIpc {
    target: "lunana.iris-sidebar-left"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.IrisSidebar {
    side: "left"
    screen: {
      const name = Inir.GlobalStates.sidebarLeftTargetOutput;
      const target = name ? Quickshell.screens.find(s => s.name === name) : null;
      return target ?? Inir.GlobalStates.focusedScreen
        ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
    }
  }

  Timer {
    interval: 200; repeat: false; running: true
    onTriggered: {
      Inir.GlobalStates.shellEntryReady = true;
      Inir.GlobalStates.deferredPanelsReady = true;
    }
  }
}
