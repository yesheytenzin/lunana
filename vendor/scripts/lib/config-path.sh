#!/usr/bin/env bash

# Library file: intended to be sourced by other scripts.
# Do not set shell options here; callers own execution mode.

# Canonical Lunana config directory is ~/.config/lunana.
# Legacy installs used ~/.config/illogical-impulse.
#
# Compatibility policy:
# - If legacy dir exists as a real directory, keep using it.
# - If legacy is a symlink and new dir exists, use new dir.
# - If only one exists, use that one.
# - If none exists, default to new dir.

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

LUNANA_CONFIG_DIR_NEW="${XDG_CONFIG_HOME}/lunana"
LUNANA_CONFIG_DIR_OLD="${XDG_CONFIG_HOME}/illogical-impulse"

lunana_config_dir() {
    # Legacy symlink -> new (post-migration steady state)
    if [[ -L "$LUNANA_CONFIG_DIR_OLD" && -d "$LUNANA_CONFIG_DIR_NEW" ]]; then
        printf '%s\n' "$LUNANA_CONFIG_DIR_NEW"
        return
    fi

    # Legacy real directory wins for backwards compatibility.
    if [[ -d "$LUNANA_CONFIG_DIR_OLD" ]]; then
        printf '%s\n' "$LUNANA_CONFIG_DIR_OLD"
        return
    fi

    # New path when legacy is absent.
    if [[ -d "$LUNANA_CONFIG_DIR_NEW" ]]; then
        printf '%s\n' "$LUNANA_CONFIG_DIR_NEW"
        return
    fi

    # Fresh install default.
    printf '%s\n' "$LUNANA_CONFIG_DIR_NEW"
}

lunana_config_file() {
    printf '%s/config.json\n' "$(lunana_config_dir)"
}

lunana_version_file() {
    printf '%s/version.json\n' "$(lunana_config_dir)"
}

lunana_installed_marker_file() {
    printf '%s/installed_true\n' "$(lunana_config_dir)"
}

lunana_migrations_state_file() {
    printf '%s/migrations.json\n' "$(lunana_config_dir)"
}
