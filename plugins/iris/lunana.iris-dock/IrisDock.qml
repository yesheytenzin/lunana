import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/dock" as LnMod
import "../../lunana-vendor/modules/iris/field" as LnField

// lunana.iris-dock — Lunana iRiS dock host (iris family only; ii dock yields while enabled). (kind: service).
//
// Resident host for inir's exact IrisDock. IrisDock is an embeddable item
// (in inir it lives inside the IrisBar chassis window), so this host provides
// the per-output layershell surface plus a per-output IrisField behind it.
// The dock paints no body itself: the chassis field paints its published
// bodyShape, and this host feeds a dedicated field exactly that (no
// cross-surface fusion with the island satellite — separate pills).
Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: true

  function open() { root.opened = true }
  function close() { root.opened = false }
  function toggle() { root.opened = !root.opened }

  ShellIpc {
    target: "lunana.iris-dock"
    function toggle(): void { root.toggle() }
    function open(): void { root.open() }
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
        WlrLayershell.namespace: "lunana-iris-dock"
        WlrLayershell.layer: WlrLayer.Top
        anchors { top: true; bottom: true; left: true; right: true }
        // Fullscreen transparent surface: only the dock body takes input.
        // The shape list is published by the dock itself per screen.
        readonly property var bodyRects: Inir.GlobalStates.irisDockBody?.[modelData.name] ?? []
        // Union of the dock body and its open menu, with margin for hover
        // magnification. Empty (auto-hidden dock) masks everything out.
        readonly property var dockRect: {
          const list = Array.isArray(bodyRects) ? bodyRects.filter(s => s && s.width > 1 && s.height > 1) : []
          if (list.length === 0)
            return { x: 0, y: 0, width: 0, height: 0 }
          let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
          for (const s of list) {
            x0 = Math.min(x0, s.x); y0 = Math.min(y0, s.y)
            x1 = Math.max(x1, s.x + s.width); y1 = Math.max(y1, s.y + s.height)
          }
          const m = 24
          return { x: x0 - m, y: y0 - m, width: x1 - x0 + m * 2, height: y1 - y0 + m * 2 }
        }
        mask: Region {
          x: dockRect.x
          y: dockRect.y
          width: dockRect.width
          height: dockRect.height
        }

        LnField.IrisField {
          anchors.fill: parent
          compositorAllowed: true
          providesBackdrop: true
          shapes: dockItem.bodyShape ?? []
        }

        LnMod.IrisDock {
          id: dockItem
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
