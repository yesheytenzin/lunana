-- lunana.lua — iNiR-owned Hyprland surface styling, loaded from the config.
--
-- Installed by `lunana-suite install` (loaded from hyprland.lua via an
-- absolute `dofile(...)` block) and removed by `lunana-suite uninstall`.
-- Coexists with Omarchy's own config — this file only adds blur layer rules
-- for lunana surfaces. Vendored iNiR surfaces keep their own `quickshell:*`
-- namespaces, so one regex covers them all; the lunana host-provided shells
-- are listed explicitly. The conf adapter (`lunana.conf`) carries the same
-- rules for Hyprland installs that still use hyprland.conf.

-- Every vendored iNiR surface (bar, overview, sidebars, etc.)
hl.layer_rule({
  match = { namespace = "^quickshell:.*$" },
  blur = true,
})

-- Lunana host-provided overlay shells
hl.layer_rule({
  match = { namespace = "^(lunana-sidebar-left|lunana-sidebar-right|lunana-iris|lunana-iris-palette|lunana-iris-control|lunana-iris-stage|lunana-iris-edit)$" },
  blur = true,
})
