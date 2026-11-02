import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/common" as LnCommon
import "../../lunana-vendor/modules/atoll/orbit" as LnMod

// lunana.atoll-orbit — Lunana Atoll orbit host (workspace overview strip). (kind: service).
//
// Resident host for lunana's exact AtollOrbit. AtollOrbit is an embeddable item
// (in lunana it lives inside the AtollBar chassis window), so this host provides
// the per-output layershell surface. Summoned with
// `omarchy-shell lunana.atoll-orbit toggle`, which drives the chassis
// GlobalStates.atollOrbitOpen flag (in lunana the hot corner does this).
// Honors the `atoll.orbit.enable` setting like the chassis loader does.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool orbitEnabled: LnCommon.Config.options?.atoll?.orbit?.enable ?? false
  readonly property bool opened: Lunana.GlobalStates.atollOrbitOpen

  function open(payloadJson) {
    if (!root.orbitEnabled) {
      console.warn("[lunana.atoll-orbit] orbit is off: turn it on in Settings › Orbit")
      return
    }
    Lunana.GlobalStates.atollOrbitOpen = true
  }
  function close() { Lunana.GlobalStates.atollOrbitOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.atoll-orbit"
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
        WlrLayershell.namespace: "lunana-atoll-orbit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        Item { anchors.fill: parent; focus: root.opened; Keys.onEscapePressed: root.close() }

        LnMod.AtollOrbit {
          anchors.fill: parent
          screen: modelData
        }
      }
    }
  }

  // Shell-entry handshake against the shared lunana-vendor/ tree (one
  // GlobalStates universe for all hosts): the vendored tree gates first paint on
  // shellEntryReady/deferredPanelsReady, which only lunana's shell.qml boot
  // sets. Mirror the minimal sequence here.
  Timer {
    interval: 200; repeat: false; running: true
    onTriggered: {
      Lunana.GlobalStates.shellEntryReady = true;
      Lunana.GlobalStates.deferredPanelsReady = true;
    }
  }
}
