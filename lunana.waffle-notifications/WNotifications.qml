import QtQuick
import Quickshell
import qs.Commons
import "vendor/" as Inir
import "vendor/modules/waffle/notificationCenter" as LnMod

// lunana.waffle-notifications — Lunana Waffle notification-center host. (kind: overlay).
//
// Hosts inir's exact WaffleNotificationCenter (modules/waffle/notificationCenter); visibility is the vendored tree's own
// GlobalStates.waffleNotificationCenterOpen, flipped here so `omarchy-shell shell toggle lunana.waffle-notifications`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.waffleNotificationCenterOpen

  function open(payloadJson) { Inir.GlobalStates.waffleNotificationCenterOpen = true }
  function close() { Inir.GlobalStates.waffleNotificationCenterOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.waffle-notifications"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.WaffleNotificationCenter {
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
