import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/sidebar" as LnMod

// lunana.iris-sidebar-right — iRiS "today" sidebar host (kind: overlay).
//
// Mirror of lunana.iris-sidebar-left for side "right": IrisSidebar is a
// layershell PanelWindow targeting GlobalStates.sidebarRightTargetOutput (set
// by openSidebarRight). The host binds its screen to that output and drives
// open/close through the vendored helpers.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.sidebarRightOpen

  function open(payloadJson) { Inir.GlobalStates.openSidebarRight("") }
  function close() { Inir.GlobalStates.closeSidebarRight() }
  function toggle() { Inir.GlobalStates.toggleSidebarRight("") }

  ShellIpc {
    target: "lunana.iris-sidebar-right"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.IrisSidebar {
    side: "right"
    screen: {
      const name = Inir.GlobalStates.sidebarRightTargetOutput;
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
