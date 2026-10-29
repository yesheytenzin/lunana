pragma Singleton
import QtQuick
import Quickshell

// LUNANA STUB (not vendored from inir) — R4 load stub.
// The Waffle bar's clock badge and widgets read list/silent; the rest keeps
// every other waffle reader shape-compatible until the notifications unit
// wires Omarchy's notification feed. All empty-safe.
Singleton {
    property var list: []
    property bool silent: false
    property int unread: 0
    property var groupsByAppName: ({})
    property var popupList: []
    property var popupGroupsByAppName: ({})
    property var appNameList: []
    property var popupAppNameList: []

    function ensureInitialized() {}
    // inir parity: the sidebar tools toggle do-not-disturb through here.
    function toggleSilent() { silent = !silent }
    function countForApp(appIds) { return 0 }
    function markReadForApp(appIds) {}
    // inir helper (services/Notifications.qml): compare on alphanumerics only.
    function _normalizeAppKey(name) {
        return String(name ?? "").toLowerCase().replace(/[^a-z0-9]/g, "")
    }
    function appNamesMatching(appIds) { return [] }
    function discardNotification(id) {}
    function discardAllNotifications() {}
    function cancelTimeout(id) {}
    function attemptInvokeAction(id, actionId) { return false }
    function send(title, body, appName, icon, urgency, actions, timeout) {}
}
