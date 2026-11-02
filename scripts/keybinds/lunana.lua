-- >>> lunana >>> (managed by lunana-suite — do not edit between these markers)
-- Lunana surfaces, toggled through the Omarchy shell's overlay lifecycle.
-- Merged into ~/.config/hypr/bindings.lua by `lunana-suite install` and removed
-- by `lunana-suite uninstall`. o.bind(keys, description, command).
-- `shell toggle <id>` is the host summon path for on-demand overlay plugins.
o.bind("SUPER + SPACE", "Lunana Overview / Spotlight", "omarchy-shell lunana.family overview")
o.bind("SUPER + SHIFT + L", "Lunana Left Sidebar / Focus", "omarchy-shell lunana.family focus")
o.bind("SUPER + SHIFT + R", "Lunana Right Sidebar / Today", "omarchy-shell lunana.family today")
o.bind("SUPER + SHIFT + C", "Lunana Control Center", "omarchy-shell lunana.family controls")
o.bind("SUPER + SLASH", "Lunana Cheatsheet", "omarchy-shell lunana.family cheatsheet")
o.bind("SUPER + SHIFT + S", "Lunana Region Snip", "omarchy-shell lunana.family region")
o.bind("SUPER + ALT + P", "Lunana Settings", "omarchy-shell lunana.family settings")
o.bind("SUPER + SHIFT + I", "Lunana Atoll Island", "omarchy-shell lunana.atoll toggle")
o.bind("SUPER + SHIFT + W", "Lunana Family Switch", "omarchy-shell lunana.family cycle")
-- <<< lunana <<<
