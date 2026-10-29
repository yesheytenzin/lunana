-- >>> lunana >>> (managed by lunana-suite — do not edit between these markers)
-- Lunana surfaces, toggled through the Omarchy shell's overlay lifecycle.
-- Merged into ~/.config/hypr/bindings.lua by `lunana-suite install` and removed
-- by `lunana-suite uninstall`. o.bind(keys, description, command).
-- `shell toggle <id>` is the host summon path for on-demand overlay plugins.
o.bind("SUPER + SHIFT + O", "Lunana Overview", "omarchy-shell shell toggle lunana.overview")
o.bind("SUPER + SHIFT + C", "Lunana Control Center", "omarchy-shell shell toggle lunana.control-center")
o.bind("SUPER + SHIFT + L", "Lunana Left Sidebar", "omarchy-shell shell toggle lunana.sidebar-left")
-- <<< lunana <<<
