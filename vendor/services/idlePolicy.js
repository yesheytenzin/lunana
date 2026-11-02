.pragma library

function niriOffCommand(quotedLunana) {
    return "'" + quotedLunana + "' brightness sleepBegin"
}

function niriResumeCommand(quotedLunana) {
    return "'" + quotedLunana + "' brightness restoreAfterWake"
}

// Hyprland has no Niri-style output-sleep IPC; dpms off/on is the nearest
// analog. Brightness save/restore still runs through the lunana launcher so the
// panel-level state stays consistent across compositors.
function hyprOffCommand(quotedLunana) {
    return "/usr/bin/sh -c \"'\" + quotedLunana + \"' brightness sleepBegin; /usr/bin/hyprctl dispatch dpms off\""
}

function hyprResumeCommand(quotedLunana) {
    return "/usr/bin/sh -c \"/usr/bin/hyprctl dispatch dpms on; '\" + quotedLunana + \"' brightness restoreAfterWake\""
}

function commandUsesDrmPowerOff(command) {
    return /power-off-monitors|power-on-monitors|PowerOffMonitors|PowerOnMonitors/.test(command)
}
