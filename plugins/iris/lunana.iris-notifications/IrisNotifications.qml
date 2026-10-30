import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/services" as LnServ
import "../../lunana-vendor/modules/iris/notificationPopup" as LnMod

// lunana.iris-notifications — Lunana iRiS banners host. (kind: service).
//
// Resident host for inir's exact IrisNotificationPopup (modules/iris/notificationPopup); it shows itself on the
// vendored tree's own state. No toggle: summoned only through the family
// switcher or not at all (see PORTING.md).
//
// Test hook: the notification bus in the nested harness belongs to the host
// session, so real `notify-send` traffic never reaches the nested popup
// model. `omarchy-shell lunana.iris-notifications test` injects one synthetic
// entry shaped like the service's wrappers straight into the popup list the
// banner delegates read (a second call clears it), proving the full banner
// render path. Bus ingress itself stays environment-limited.
Item {
  id: root

  property var shell: null
  property var manifest: null

  function test() {
    const Svc = LnServ.Notifications
    if ((Svc.popupList ?? []).length > 0) {
      Svc.popupList = []
      return "cleared"
    }
    // Flat wrapper shape, exactly what the service's notifComponent
    // publishes (the banner delegates read modelData.summary/.body/...).
    Svc.popupList = [{
      notificationId: 999001,
      popup: true,
      time: Date.now(),
      appName: "Lunana test",
      appIcon: "",
      image: "",
      summary: "Banner render test",
      body: "Synthetic entry: the bus is owned by the host session.",
      urgency: "normal",
      actions: []
    }]
    return "shown n=" + Svc.popupList.length
      + " summary=" + String((Svc.popupList[0] ?? {}).summary ?? "")
  }

  ShellIpc {
    target: "lunana.iris-notifications"
    function test(): string { return root.test() }
  }

  LnMod.IrisNotificationPopup {
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
