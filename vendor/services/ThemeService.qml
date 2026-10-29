pragma Singleton
import QtQuick
import Quickshell
import "../modules/common" as LnCommon

// LUNANA SHIM (not vendored from inir) — Wave-C load stub.
// The iRiS token family (IrisStyle/IrisWashi/IrisAppsSync) reads the theme
// selection behind these members; live theme switching (regeneration,
// wallpaper seeding, Material sync) lands with the theme unit.
Singleton {
    readonly property string currentTheme: LnCommon.Config.options?.appearance?.theme ?? "auto"
    readonly property bool isAutoTheme: currentTheme === "auto"
    readonly property string panelFamily: "lunana"
    readonly property bool irisMaterialApps: false
    function regenerateAutoTheme() {}
}
