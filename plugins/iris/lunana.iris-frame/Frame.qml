pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/field" as LnField
import "../../lunana-vendor/modules/iris/frame" as LnFrame

// lunana.iris-frame — iRiS surround frame for the satellite model. (kind: service).
//
// Native iRiS draws the "warp around" look with one chassis IrisField whose
// frame band molds the tiled window area around the island/dock. The satellite
// model (Option A) has no chassis, so windows are plain rectangles. This host
// renders a per-output fullscreen IrisField over the windows with framed=true:
// the shader draws the screen-edge glass band plus the notches IrisFrame leaves
// at the island and dock edges, so tiled windows appear molded around them.
// The island and dock pills (their own satellites) sit inside those notches.
//
// The band is only non-zero when iris.surround.enable is on (IrisFrame.framed),
// so this surface is inert until surround is enabled — matching inir, where the
// frame is the surround feature. Input passes through entirely (empty mask);
// the field is transparent outside the band.
Scope {
    id: root

    property var shell: null
    property var manifest: null

    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                visible: LnFrame.IrisFrame.framed
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 0
                WlrLayershell.namespace: "lunana-iris-frame"
                // Over tiled windows (so the band molds their edges) but the
                // island/dock satellites sit above it on their own Top windows.
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                anchors { top: true; bottom: true; left: true; right: true }
                mask: Region {}

                LnField.IrisField {
                    anchors.fill: parent
                    compositorAllowed: true
                    providesBackdrop: true
                    framed: true
                    shapes: LnFrame.IrisFrame.placeShapesOn(modelData?.name ?? "")
                }
            }
        }
    }

    // Shell-entry handshake in this plugin's singleton universe.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Inir.GlobalStates.shellEntryReady = true;
            Inir.GlobalStates.deferredPanelsReady = true;
        }
    }
}
