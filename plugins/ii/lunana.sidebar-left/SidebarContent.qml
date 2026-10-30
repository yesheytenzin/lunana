import QtQuick
import "../../lunana-vendor/modules/sidebarLeft" as LSLeft

// Separately-compiled wrapper around the vendored ii left sidebar.
//
// Keeping the vendored type out of SidebarLeft.qml's own compilation unit is
// what makes graceful degradation possible: if an optional QML dependency is
// missing (currently org.kde.syntaxhighlighting, imported by AiChat's code
// blocks), the Loader in the host reports an error and shows a diagnostic
// instead of failing the whole overlay plugin. The host fills in panelVisible,
// panelScreen, screenWidth, and screenHeight through bindings.
LSLeft.SidebarLeftContent {
  anchors.fill: parent
}
