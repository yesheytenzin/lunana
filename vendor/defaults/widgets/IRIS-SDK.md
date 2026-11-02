# Atoll Module SDK

Atoll bar modules use the existing Lunana CustomWidgets registry. There is no second plugin format or
scanner. A widget may provide its normal desktop component, an Atoll compact component, or both.

## Create a module

```bash
lunana customWidgets create my-widget
```

The generated manifest includes an `atoll` block and the scaffold includes `AtollCompact.qml`.
Reload after editing:

```bash
lunana customWidgets reload
```

Turn it on in **Atoll Settings > Island > Desktop page > Your modules** (the row shows up once a module is installed; search for "modules"). It
lands in the Modules block of the Island's Desktop page. Material's Settings has the same switch
under **Atoll > Modules**.

## Manifest

```json
{
  "name": "My Widget",
  "main": "MyWidget.qml",
  "atoll": {
    "main": "AtollCompact.qml",
    "slots": ["island.desktop"]
  }
}
```

`slots` is optional. Right now there is one place a module can live, the Island's Desktop page, and
the component gets it as `atollSlot` (`"island.desktop"`). Declaring it keeps the manifest honest
for when there are more.

The module list is `atoll.bar.rightModules`, ordered, with entries like `"custom:my-widget"`. Settings
writes it for you; no other registration is needed.

## Minimal compact component

```qml
pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.atoll.style
import qs.modules.atoll.components

Item {
    property string atollSlot: ""
    property var targetScreen

    implicitWidth: row.implicitWidth
    implicitHeight: Math.round(28 * AtollStyle.density)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: AtollStyle.spaceSmall

        AtollMark { implicitSize: Math.round(14 * AtollStyle.density) }
        AtollText {
            role: AtollText.Meta
            text: DateTime.timeDisplay
            font.family: AtollStyle.fontNumbers
        }
    }
}
```

## Compact API

Use these first:

- `AtollStyle`: colors, fonts, density, radii, spacing, motion duration and text sizes
  (`typeCaption` 10, `typeFootnote` 11, `typeMeta` 12, `typeLabel` 13, `typeBody` 14,
  `typeHeadline` 15, `typeTitle` 17, `typeTitleLarge` 21, `typeDisplay` 28). Use those instead of
  `N * typeScale`, and keep spacing on even steps of `AtollStyle.density` (2, 4, 6, 8, 10, 12…);
- `AtollText`: roles that set size, weight and ink together (`Body`, `Meta`, `Title`, `Display`,
  `Metric`, `Eyebrow`);
- `AtollSurface`: normal/raised surface;
- `AtollButton` / `AtollIconButton`: hover/tap/selected states;
- `AtollSegmented` and `AtollSwitch`: the same segmented control and switch Atoll Settings uses;
- `AtollMark`: family mark;
- `AtollSlider`: compact slider (use `AtollCapsuleSlider` for Control Center style levels).

Looks that fit: a group is a fill (`AtollStyle.fillQuiet`), not a bordered box; a control carries its
state in its fill and ink, not in a badge next to it; colour means something (accent for on or
selected, identity hues for a fixed meaning), never decoration.

Normal Lunana services remain available through `import qs.services`, but a compact module should
import only what it actually needs. Avoid pulling in media visualizers, preview services or
background processes for a value that is not continuously visible.

## Lifecycle rules

- Do not start a subprocess from a hidden component just to cache data.
- Do not use a permanent animation for decoration.
- Prefer service signals over polling timers.
- Keep module failure local; do not mutate family loader state.
- Respect `targetScreen` for output-specific data.
- Use `Config.setNestedValue(...)` for persistent writes; do not assign into `Config.options`.
- Keep presentation in Atoll tokens rather than hard-coded theme colors.

For full desktop-widget APIs and the broader service/component catalog, see `WIDGET-SDK.md`.
