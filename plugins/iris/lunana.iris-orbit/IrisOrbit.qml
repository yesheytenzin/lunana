import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/common" as LnCommon
import "../../lunana-vendor/modules/iris/orbit" as LnMod

// lunana.iris-orbit — Lunana iRiS orbit host (workspace overview strip). (kind: service).
//
// Resident host for inir's exact IrisOrbit. IrisOrbit is an embeddable item
// (in inir it lives inside the IrisBar chassis window), so this host provides
// the per-output layershell surface. Summoned with
// `omarchy-shell lunana.iris-orbit toggle`, which drives the chassis
// GlobalStates.irisOrbitOpen flag (in inir the hot corner does this).
// Honors the `iris.orbit.enable` setting like the chassis loader does.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool orbitEnabled: LnCommon.Config.options?.iris?.orbit?.enable ?? false
  readonly property bool opened: Inir.GlobalStates.irisOrbitOpen

  function open(payloadJson) {
    if (!root.orbitEnabled) {
      console.warn("[lunana.iris-orbit] orbit is off: turn it on in Settings › Orbit")
      return
    }
    Inir.GlobalStates.irisOrbitOpen = true
  }
  function close() { Inir.GlobalStates.irisOrbitOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.iris-orbit"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  Variants {
    model: Quickshell.screens
    delegate: Component {
      PanelWindow {
        required property var modelData
        screen: modelData
        visible: root.opened
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.namespace: "lunana-iris-orbit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        Item { anchors.fill: parent; focus: root.opened; Keys.onEscapePressed: root.close() }

        LnMod.IrisOrbit {
          anchors.fill: parent
          screen: modelData
        }
      }
    }
  }

  // Shell-entry handshake in this plugin's singleton universe (each
  // installed plugin carries its own vendor/ copy, hence its own
  // GlobalStates): the vendored tree gates first paint on
  // shellEntryReady/deferredPanelsReady, which only inir's shell.qml boot
  // sets. Mirror the minimal sequence here.
  Timer {
    interval: 200; repeat: false; running: true
    onTriggered: {
      Inir.GlobalStates.shellEntryReady = true;
      Inir.GlobalStates.deferredPanelsReady = true;
    }
  }
}
