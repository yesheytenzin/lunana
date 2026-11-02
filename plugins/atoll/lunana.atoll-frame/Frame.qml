pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/atoll/field" as LnField
import "../../lunana-vendor/modules/atoll/frame" as LnFrame

// lunana.atoll-frame — Atoll surround frame for the satellite model. (kind: service).
//
// Native Atoll draws the "warp around" look with one chassis AtollField whose
// frame band molds the tiled window area around the island/dock. The satellite
// model (Option A) has no chassis, so windows are plain rectangles. This host
// renders a per-output fullscreen AtollField over the windows with framed=true:
// the shader draws the screen-edge glass band plus the notches AtollFrame leaves
// at the island and dock edges, so tiled windows appear molded around them.
// The island and dock pills (their own satellites) sit inside those notches.
//
// The band is only non-zero when atoll.surround.enable is on (AtollFrame.framed),
// so this surface is inert until surround is enabled — matching lunana, where the
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
                visible: LnFrame.AtollFrame.framed
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 0
                WlrLayershell.namespace: "lunana-atoll-frame"
                // Over tiled windows (so the band molds their edges) but the
                // island/dock satellites sit above it on their own Top windows.
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                anchors { top: true; bottom: true; left: true; right: true }
                mask: Region {}

                LnField.AtollField {
                    anchors.fill: parent
                    compositorAllowed: true
                    providesBackdrop: true
                    framed: true
                    shapes: LnFrame.AtollFrame.placeShapesOn(modelData?.name ?? "")
                }
            }
        }
    }

    // Shell-entry handshake against the shared lunana-vendor/ tree
    // (one GlobalStates universe for all hosts).
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Lunana.GlobalStates.shellEntryReady = true;
            Lunana.GlobalStates.deferredPanelsReady = true;
        }
    }
}
