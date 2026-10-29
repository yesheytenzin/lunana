.pragma library

function niriOffCommand(quotedInir) {
    return "'" + quotedInir + "' brightness sleepBegin"
}

function niriResumeCommand(quotedInir) {
    return "'" + quotedInir + "' brightness restoreAfterWake"
}

// Hyprland has no Niri-style output-sleep IPC; dpms off/on is the nearest
// analog. Brightness save/restore still runs through the inir launcher so the
// panel-level state stays consistent across compositors.
function hyprOffCommand(quotedInir) {
    return "/usr/bin/sh -c \"'\" + quotedInir + \"' brightness sleepBegin; /usr/bin/hyprctl dispatch dpms off\""
}

function hyprResumeCommand(quotedInir) {
    return "/usr/bin/sh -c \"/usr/bin/hyprctl dispatch dpms on; '\" + quotedInir + \"' brightness restoreAfterWake\""
}

function commandUsesDrmPowerOff(command) {
    return /power-off-monitors|power-on-monitors|PowerOffMonitors|PowerOnMonitors/.test(command)
}
