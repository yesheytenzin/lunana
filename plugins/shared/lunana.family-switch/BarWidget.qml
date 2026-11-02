import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// lunana.family-switch — bar widget + family picker (kind: bar-widget).
//
// Lives on every bar (including stock omarchy.bar) so no family strands the
// user without a way back. The button shows the current family; clicking it
// opens a picker card with all four families, and picking one runs
// `omarchy-shell lunana.family set <name>` through the bar host.
BarWidget {
  id: root
  moduleName: "lunana.family-switch"

  readonly property var families: [
    { id: "drift", label: "Drift" },
    { id: "slate", label: "Slate" },
    { id: "atoll", label: "Atoll" },
    { id: "stock", label: "Stock" }
  ]
  readonly property string family: {
    try {
      var parsed = JSON.parse(shellFile.text())
      var section = parsed ? parsed.lunana : null
      var fam = section ? section.family : null
      return fam ? String(fam) : "stock"
    } catch (err) {}
    return "stock"
  }
  readonly property string familyLabel: {
    for (var i = 0; i < root.families.length; i++) {
      if (root.families[i].id === root.family) return root.families[i].label
    }
    return root.family
  }

  FileView {
    id: shellFile
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    blockLoading: true
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }

  property bool pickerOpen: false

  function choose(name: string): void {
    root.pickerOpen = false
    var cmd = "omarchy-shell lunana.family set " + name
    if (root.bar && typeof root.bar.run === "function") root.bar.run(cmd)
    else Quickshell.execDetached(["omarchy-shell", "lunana.family", "set", name])
  }

  function togglePicker(): void {
    root.pickerOpen = !root.pickerOpen
  }

  // Icon button (exchange glyph): the bar shows a mark, not a word. The
  // tooltip names the current family; the picker rows keep their labels.
  BarIconButton {
    id: button
    bar: root.bar
    text: "\uf0ec"
    tooltipText: "Lunana family: " + root.familyLabel + " — switch panel family"
    onPressed: root.togglePicker()
  }

  // Fixed-geometry picker: every size here is a literal, so opening it can
  // never feed back into layout (a content-sized card crashed the shell
  // through a Column polish loop). Four static rows, no models.
  component FamilyRow: Rectangle {
    id: row
    required property string familyId
    required property string familyLabel
    readonly property bool current: row.familyId === root.family
    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: 36
    radius: 8
    color: rowMouse.containsMouse ? Commons.Color.accent : "transparent"
    opacity: rowMouse.containsMouse ? 0.22 : 1.0

    Row {
      anchors.fill: parent
      anchors.leftMargin: 12
      anchors.rightMargin: 12
      spacing: 10

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: row.current ? "●" : "○"
        color: row.current ? Commons.Color.accent : Commons.Color.muted
        font.pixelSize: 11
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: row.familyLabel
        color: Commons.Color.popups.text
        font.pixelSize: 13
        font.weight: row.current ? Font.DemiBold : Font.Normal
      }
    }

    MouseArea {
      id: rowMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onPressed: root.choose(row.familyId)
      onClicked: root.choose(row.familyId)
    }
  }

  PopupWindow {
    id: picker
    visible: root.pickerOpen
    color: "transparent"
    implicitWidth: 220
    implicitHeight: 184

    anchor {
      window: button.QsWindow ? button.QsWindow.window : null
      adjustment: PopupAdjustment.Slide
      edges: Edges.Top | Edges.Left
      gravity: Edges.Bottom | Edges.Right
      onAnchoring: {
        var win = button.QsWindow ? button.QsWindow.window : null
        if (!win) return
        var p = button.mapToItem(win.contentItem, 0, button.height + 6)
        var w = picker.implicitWidth
        var h = picker.implicitHeight
        picker.anchor.rect.x = Math.max(8, Math.min(p.x - w / 2, win.width - w - 8))
        picker.anchor.rect.y = Math.max(0, Math.min(p.y, win.height - h))
        picker.anchor.rect.width = 1
        picker.anchor.rect.height = 1
      }
    }

    // No focus grab: it swallowed row presses on some compositors. The
    // button toggles and every row closes, so the card can never stick.
    // Clicking elsewhere leaves it open until the button is pressed again.

    Rectangle {
      anchors.fill: parent
      color: Commons.Color.popups.background
      border.color: Commons.Color.popups.border
      border.width: 1
      radius: 12

      Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 2

        FamilyRow { familyId: "drift"; familyLabel: "Drift" }
        FamilyRow { familyId: "slate"; familyLabel: "Slate" }
        FamilyRow { familyId: "atoll"; familyLabel: "Atoll" }
        FamilyRow { familyId: "stock"; familyLabel: "Stock" }
      }
    }
  }
}
