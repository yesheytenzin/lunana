-- lunana.lua — Lunana-owned Hyprland surface styling, loaded from the config.
--
-- Installed by `lunana-suite install` (loaded from hyprland.lua via an
-- absolute `dofile(...)` block) and removed by `lunana-suite uninstall`.
-- Coexists with Omarchy's own config — this file only adds blur layer rules
-- for lunana surfaces. Vendored Lunana surfaces keep their own `quickshell:*`
-- namespaces, so one regex covers them all; the lunana host-provided shells
-- are listed explicitly. The conf adapter (`lunana.conf`) carries the same
-- rules for Hyprland installs that still use hyprland.conf.

-- Every vendored Lunana surface (bar, overview, sidebars, etc.)
hl.layer_rule({
  match = { namespace = "^quickshell:.*$" },
  blur = true,
})

-- Lunana host-provided overlay shells
hl.layer_rule({
  match = { namespace = "^(lunana-sidebar-left|lunana-sidebar-right|lunana-atoll|lunana-atoll-palette|lunana-atoll-control|lunana-atoll-stage|lunana-atoll-edit)$" },
  blur = true,
})
