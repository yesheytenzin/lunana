# Uninstall command for Lunana
# Safely removes Lunana while preserving user data and shared resources
# This script is meant to be sourced.

# shellcheck shell=bash

LUNANA_CONFIG_DIR="${DOTS_CORE_CONFDIR:-${XDG_CONFIG_HOME}/lunana}"

###############################################################################
# Configuration - What Lunana installs/manages
###############################################################################

# Categories of files:
# - lunana_only: Files created exclusively by Lunana, safe to remove
# - shared: Files that may be used by other apps, ask before removing
# - user_data: User's personal data, preserve by default

# Lunana-exclusive files (safe to remove)
declare -A LUNANA_ONLY_PATHS=(
    ["${XDG_CONFIG_HOME}/quickshell/lunana"]="Lunana shell configuration"
    ["${LUNANA_CONFIG_DIR}"]="Lunana user preferences"
    ["${XDG_STATE_HOME}/quickshell/user"]="Lunana state (notifications, todo)"
    ["${XDG_CACHE_HOME}/quickshell/lunana"]="Lunana cache"
    ["${XDG_BIN_HOME}/lunana"]="Lunana launcher"
    ["${HOME}/.local/bin/lunana_super_overview_daemon.py"]="Lunana super daemon"
    ["${XDG_CONFIG_HOME}/systemd/user/lunana.service"]="Lunana user service"
    ["${XDG_CONFIG_HOME}/systemd/user/lunana-super-overview.service"]="Lunana daemon service"
    ["${XDG_CONFIG_HOME}/service/lunana"]="Lunana runit user service"
    ["${XDG_CONFIG_HOME}/service/lunana-xembedsniproxy"]="Lunana XEmbed runit service"
    ["${XDG_CONFIG_HOME}/service/lunana-super-overview"]="Lunana Super-tap runit service"
    ["${XDG_CONFIG_HOME}/vesktop/themes/system24.theme.css"]="Lunana Vesktop Material theme"
    ["${XDG_CONFIG_HOME}/vesktop/themes/lunana-tui.theme.css"]="Lunana Vesktop TUI theme"
    ["${XDG_CONFIG_HOME}/vesktop/themes/lunana-midnight.theme.css"]="Lunana Vesktop Midnight theme"
    ["${XDG_CONFIG_HOME}/vesktop/themes/drift-colors.css"]="Lunana Vesktop colors"
    ["${XDG_CONFIG_HOME}/Vesktop/themes/system24.theme.css"]="Lunana Vesktop Material theme (alt)"
    ["${XDG_CONFIG_HOME}/Vesktop/themes/lunana-tui.theme.css"]="Lunana Vesktop TUI theme (alt)"
    ["${XDG_CONFIG_HOME}/Vesktop/themes/lunana-midnight.theme.css"]="Lunana Vesktop Midnight theme (alt)"
    ["${XDG_CONFIG_HOME}/Vesktop/themes/drift-colors.css"]="Lunana Vesktop colors (alt)"
    ["${XDG_DATA_HOME}/applications/lunana.desktop"]="Lunana desktop entry"
    ["${XDG_DATA_HOME}/applications/lunana-settings.desktop"]="Lunana settings desktop entry"
    ["${XDG_DATA_HOME}/icons/hicolor/scalable/apps/lunana.svg"]="Lunana launcher icon"
    ["${HOME}/.local/bin/sync-pixel-sddm.py"]="Lunana SDDM theme sync helper"
)

# Shared configs - may be used by other apps or user customizations
# Format: path -> "description|app_command|critical_level"
# critical_level: essential (user likely needs), optional (can remove), lunana_default (Lunana created)
declare -A SHARED_PATHS=(
    ["${XDG_CONFIG_HOME}/niri/config.kdl"]="Niri compositor config|niri|essential"
    ["${XDG_CONFIG_HOME}/matugen"]="Lunana theming templates|python3|optional"
    ["${XDG_CONFIG_HOME}/fuzzel"]="Fuzzel launcher config|fuzzel|optional"
    ["${XDG_CONFIG_HOME}/Kvantum"]="Kvantum Qt theme|kvantummanager|optional"
    ["${XDG_CONFIG_HOME}/kdeglobals"]="KDE global settings||optional"
    ["${XDG_CONFIG_HOME}/dolphinrc"]="Dolphin file manager config|dolphin|optional"
    ["${XDG_CONFIG_HOME}/gtk-3.0/gtk.css"]="GTK3 custom styles||optional"
    ["${XDG_CONFIG_HOME}/gtk-4.0/gtk.css"]="GTK4 custom styles||optional"
    ["${XDG_CONFIG_HOME}/fontconfig/conf.d/90-lunana-shell.conf"]="Lunana shell font rendering||lunana_default"
    ["${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes/Darkly.colors"]="Darkly color scheme||lunana_default"
)

# Quickshell state that may be shared with other quickshell configs
declare -A QUICKSHELL_SHARED=(
    ["${XDG_STATE_HOME}/quickshell/.venv"]="Python virtual environment"
    ["${XDG_STATE_HOME}/quickshell/themes"]="Generated themes"
)

declare -A LUNANA_PREINSTALL_RESTORE_FILES=(
    ["${XDG_CONFIG_HOME}/starship.toml"]="Starship config"
    ["${XDG_CONFIG_HOME}/fish/config.fish"]="Fish config"
    ["${XDG_CONFIG_HOME}/fish/auto-Niri.fish"]="Fish Niri integration"
    ["${XDG_CONFIG_HOME}/foot/foot.ini"]="Foot config"
    ["${XDG_CONFIG_HOME}/kitty/kitty.conf"]="Kitty config"
    ["${XDG_CONFIG_HOME}/konsolerc"]="Konsole config"
    ["${XDG_CONFIG_HOME}/chrome-flags.conf"]="Chrome flags"
    ["${XDG_CONFIG_HOME}/code-flags.conf"]="VS Code flags"
    ["${XDG_CONFIG_HOME}/mpv/mpv.conf"]="MPV config"
)

# Packages that Lunana may have installed - with usage context
# Format: command -> "package_name|description|shared_usage"
# shared_usage: lunana_only, compositor, system_tool, optional_tool
declare -A LUNANA_PACKAGES=(
    ["qs"]="quickshell|Shell framework|lunana_only"
    ["niri"]="niri|Wayland compositor|compositor"
    ["cliphist"]="cliphist|Clipboard history|system_tool"
    ["fuzzel"]="fuzzel|Application launcher|system_tool"
    ["swaylock"]="swaylock|Screen locker|system_tool"
    ["grim"]="grim|Screenshot tool|system_tool"
    ["slurp"]="slurp|Region selector|system_tool"
    ["wl-copy"]="wl-clipboard|Clipboard utilities|system_tool"
    ["brightnessctl"]="brightnessctl|Brightness control|system_tool"
    ["playerctl"]="playerctl|Media control|system_tool"
    ["plasma-browser-integration-host"]="plasma-browser-integration|Browser media integration|system_tool"
    ["dunstify"]="dunst|Notification daemon|system_tool"
    ["cava"]="cava|Audio visualizer|optional_tool"
    ["easyeffects"]="easyeffects|Audio effects|optional_tool"
)

###############################################################################
# Detection functions
###############################################################################

# Check if user has other quickshell configurations
has_other_quickshell_configs() {
    local qs_dir="${XDG_CONFIG_HOME}/quickshell"
    if [[ -d "$qs_dir" ]]; then
        local other_configs
        other_configs=$(find "$qs_dir" -mindepth 2 -maxdepth 2 -type f -name "shell.qml" \
            ! -path "${qs_dir}/lunana/shell.qml" \
            ! -path "${qs_dir}/drift/shell.qml" 2>/dev/null | wc -l)
        [[ "$other_configs" -gt 0 ]]
    else
        return 1
    fi
}

# Check if user is currently running Niri (would break their session)
is_running_niri_session() {
    [[ -n "$NIRI_SOCKET" ]] || pgrep -x niri &>/dev/null
}

# Check if user has other dotfiles that use niri
has_other_niri_usage() {
    # Check for niri in other common dotfile locations
    local niri_refs=0
    
    # Check if niri is in user's shell startup
    grep -q "niri" "${HOME}/.bashrc" 2>/dev/null && ((niri_refs++))
    grep -q "niri" "${HOME}/.zshrc" 2>/dev/null && ((niri_refs++))
    grep -q "niri" "${XDG_CONFIG_HOME}/fish/config.fish" 2>/dev/null && ((niri_refs++))
    
    # Check for niri in display manager configs
    [[ -f "/usr/share/wayland-sessions/niri.desktop" ]] && ((niri_refs++))
    
    # If niri is referenced elsewhere, user likely uses it independently
    [[ $niri_refs -gt 0 ]]
}

# Check if niri config has Lunana-specific content or is user-customized
niri_config_is_lunana_default() {
    local config="${XDG_CONFIG_HOME}/niri/config.kdl"
    [[ -f "$config" ]] && grep -qE 'spawn-at-startup "([^"]*/)?lunana" "start"|spawn-at-startup "qs" "-c" "lunana"|quickshell:driftBackdrop' "$config" 2>/dev/null
}

# Check if niri config has user customizations beyond Lunana defaults
niri_config_has_user_customizations() {
    local config="${XDG_CONFIG_HOME}/niri/config.kdl"
    [[ ! -f "$config" ]] && return 1
    
    # Check for common user customizations
    local custom_markers=(
        "// Custom"
        "# Custom"
        "// My "
        "# My "
        "// User"
        "# User"
    )
    
    for marker in "${custom_markers[@]}"; do
        grep -qi "$marker" "$config" 2>/dev/null && return 0
    done
    
    # Check if file was modified after Lunana install
    local install_marker="${LUNANA_CONFIG_DIR}/installed_true"
    if [[ -f "$install_marker" && -f "$config" ]]; then
        [[ "$config" -nt "$install_marker" ]] && return 0
    fi
    
    return 1
}

# Check if a config file was modified by user (compare to defaults if available)
config_was_user_modified() {
    local config_path="$1"
    local runtime_dir
    runtime_dir="$(get_runtime_shell_dir)"
    local repo_dots="${runtime_dir:+${runtime_dir}/dots}"
    local default_path="${repo_dots:+${repo_dots}/.config/${config_path#${XDG_CONFIG_HOME}/}}"
    
    if [[ -n "$default_path" && -f "$default_path" && -f "$config_path" ]]; then
        ! diff -q "$config_path" "$default_path" &>/dev/null
    else
        # If no default to compare, assume user modified
        return 0
    fi
}

# Parse shared path metadata
# Returns: description, app_command, critical_level
parse_shared_path_meta() {
    local meta="$1"
    IFS='|' read -r SHARED_DESC SHARED_APP SHARED_LEVEL <<< "$meta"
}

# Check if an app is installed and might use a config
app_uses_config() {
    local path="$1"
    local meta="${SHARED_PATHS[$path]}"
    
    parse_shared_path_meta "$meta"
    
    # If no app command specified, check by path pattern
    if [[ -z "$SHARED_APP" ]]; then
        case "$path" in
            *gtk*) return 0 ;; # GTK is always present
            *fontconfig*) return 0 ;; # fontconfig is always present
            *) return 1 ;;
        esac
    fi
    
    command -v "$SHARED_APP" &>/dev/null
}

# Check if a package is used by other applications (reverse dependency check)
package_has_dependents() {
    local pkg="$1"
    local distro="${OS_GROUP_ID:-unknown}"
    
    case "$distro" in
        arch)
            # Check if anything depends on this package
            local deps=$(pacman -Qi "$pkg" 2>/dev/null | grep "Required By" | cut -d: -f2)
            [[ "$deps" != " None" && -n "$deps" ]]
            ;;
        fedora)
            # Check reverse dependencies
            local deps=$(dnf repoquery --whatrequires "$pkg" 2>/dev/null | head -1)
            [[ -n "$deps" ]]
            ;;
        debian|ubuntu)
            # Check reverse dependencies
            local deps=$(apt-cache rdepends "$pkg" 2>/dev/null | grep -v "^$pkg$" | head -1)
            [[ -n "$deps" ]]
            ;;
        void)
            # XBPS prints reverse dependencies one per line; no output means none.
            local deps=$(xbps-query -X "$pkg" 2>/dev/null | head -1)
            [[ -n "$deps" ]]
            ;;
        *)
            # Can't check, assume it might have dependents
            return 0
            ;;
    esac
}

# Determine if a package is safe to suggest removal
get_package_removal_safety() {
    local cmd="$1"
    local meta="${LUNANA_PACKAGES[$cmd]}"
    
    [[ -z "$meta" ]] && echo "unknown" && return
    
    IFS='|' read -r pkg_name pkg_desc pkg_usage <<< "$meta"
    
    case "$pkg_usage" in
        lunana_only)
            # Only used by Lunana - safe to remove if no other qs configs
            if has_other_quickshell_configs; then
                echo "keep_qs"
            else
                echo "safe"
            fi
            ;;
        compositor)
            # Niri - check if user is in a Niri session or uses it elsewhere
            if is_running_niri_session; then
                echo "keep_session"
            elif has_other_niri_usage; then
                echo "keep_user"
            else
                echo "ask"
            fi
            ;;
        system_tool)
            # Tools that might be used by other apps
            if package_has_dependents "$pkg_name"; then
                echo "keep_deps"
            else
                echo "ask"
            fi
            ;;
        optional_tool)
            # Optional tools - generally safe to remove
            echo "safe"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

###############################################################################
# Uninstall functions
###############################################################################

uninstall_stop_services() {
    tui_info "Stopping Lunana services..."

    local user_service_root="${XDG_CONFIG_HOME:-$HOME/.config}/service"
    local service_dir
    if command -v sv >/dev/null 2>&1; then
        for service_dir in lunana lunana-xembedsniproxy lunana-super-overview; do
            [[ -d "$user_service_root/$service_dir" ]] || continue
            sv down "$user_service_root/$service_dir" >/dev/null 2>&1 || true
        done
        if [[ -f "$user_service_root/ydotool/run" ]] \
                && grep -q '^# Managed by Lunana\.' "$user_service_root/ydotool/run"; then
            sv down "$user_service_root/ydotool" >/dev/null 2>&1 || true
        fi
    fi

    # Stop quickshell lunana config
    local runtime_target="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/lunana"
    qs -p "$runtime_target" kill 2>/dev/null || true

    # Stop super daemon if running
    if has_usable_systemd_user_manager; then
        # Stop the service
        systemctl --user stop lunana.service 2>/dev/null || true
        # Remove all wants links (compositor-specific and legacy graphical-session)
        local _sd_user="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
        for _wd in "$_sd_user"/*.wants; do
            [[ -d "$_wd" ]] || continue
            rm -f "$_wd/lunana.service" 2>/dev/null || true
        done
        # Also try legacy disable in case old [Install] symlinks exist
        systemctl --user disable lunana.service 2>/dev/null || true
        systemctl --user reset-failed lunana.service 2>/dev/null || true

        if systemctl --user is-active lunana-super-overview.service &>/dev/null; then
            systemctl --user disable --now lunana-super-overview.service 2>/dev/null || true
        fi
        systemctl --user reset-failed lunana-super-overview.service 2>/dev/null || true
    fi

    tui_success "Services stopped"
}

uninstall_reload_user_systemd() {
    if has_usable_systemd_user_manager; then
        systemctl --user daemon-reload 2>/dev/null || true
    fi
}

uninstall_backup_restorable_configs() {
    local backup_dir="$1" target candidate rel destination

    for target in "${!LUNANA_PREINSTALL_RESTORE_FILES[@]}"; do
        for candidate in "$target" "$target.old"; do
            [[ -e "$candidate" || -L "$candidate" ]] || continue
            rel="${candidate#${XDG_CONFIG_HOME}/}"
            destination="$backup_dir/shared-configs/$rel"
            mkdir -p "$(dirname "$destination")"
            cp -a -- "$candidate" "$destination"
        done
    done
}

uninstall_backup_shell_integration() {
    local backup_dir="$1" profile destination
    mkdir -p "$backup_dir/shell-integration"

    for profile in "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc" \
                   "$HOME/.zprofile" "$HOME/.zshrc"; do
        [[ -f "$profile" ]] || continue
        destination="$backup_dir/shell-integration/$(basename "$profile")"
        cp -a -- "$profile" "$destination"
    done

    for profile in "${XDG_CONFIG_HOME}/fish/conf.d/lunana-path.fish" \
                   "${XDG_CONFIG_HOME}/fish/conf.d/lunana-env.fish"; do
        [[ -e "$profile" || -L "$profile" ]] || continue
        destination="$backup_dir/shell-integration/$(basename "$profile")"
        cp -a -- "$profile" "$destination"
    done
}

uninstall_remove_shell_integration() {
    local profile tmp changed=0

    for profile in "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc" \
                   "$HOME/.zprofile" "$HOME/.zshrc"; do
        [[ -f "$profile" ]] || continue
        tmp="${profile}.lunana-uninstall.$$"
        python3 - "$profile" > "$tmp" <<'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
for start, end in (
    ("Lunana launcher PATH", "end Lunana launcher PATH"),
    ("Lunana environment", "end Lunana"),
):
    pattern = rf"(?ms)^[ \t]*# {re.escape(start)}[ \t]*$\n.*?^[ \t]*# {re.escape(end)}[ \t]*$\n?"
    text = re.sub(pattern, "", text)
sys.stdout.write(text)
PY
        if ! cmp -s "$profile" "$tmp"; then
            mv "$tmp" "$profile"
            ((changed++)) || true
        else
            rm -f "$tmp"
        fi
    done

    for profile in "${XDG_CONFIG_HOME}/fish/conf.d/lunana-path.fish" \
                   "${XDG_CONFIG_HOME}/fish/conf.d/lunana-env.fish"; do
        if [[ -e "$profile" || -L "$profile" ]]; then
            rm -f -- "$profile" || return 1
            ((changed++)) || true
        fi
    done

    if [[ "$changed" -gt 0 ]]; then
        tui_success "Removed Lunana shell profile integration"
    fi
}

uninstall_restore_backup_path() {
    local relative="$1" target source
    target="${XDG_CONFIG_HOME}/$relative"
    source="${BACKUP_DIR}/.config/$relative"
    [[ -e "$source" || -L "$source" ]] || return 1
    mkdir -p "$(dirname "$target")"
    rm -f -- "$target"
    cp -a -- "$source" "$target"
}

uninstall_restore_preinstall_configs() {
    local target old relative desc restored=0

    echo ""
    tui_section_start "Restoring pre-Lunana configs"
    for target in "${!LUNANA_PREINSTALL_RESTORE_FILES[@]}"; do
        old="$target.old"
        relative="${target#${XDG_CONFIG_HOME}/}"
        desc="${LUNANA_PREINSTALL_RESTORE_FILES[$target]}"

        if [[ -e "$old" || -L "$old" ]]; then
            mkdir -p "$(dirname "$target")"
            rm -f -- "$target"
            mv -- "$old" "$target"
            echo -e "  ${STY_GREEN}✓${STY_RST} Restored: $desc"
            ((restored++)) || true
        elif [[ -e "${BACKUP_DIR}/.config/$relative" || -L "${BACKUP_DIR}/.config/$relative" ]]; then
            uninstall_restore_backup_path "$relative"
            echo -e "  ${STY_GREEN}✓${STY_RST} Restored from install backup: $desc"
            ((restored++)) || true
        fi
    done

    local kitty_theme="${XDG_CONFIG_HOME}/kitty/theme.conf"
    local kitty_link="${XDG_CONFIG_HOME}/kitty/current-theme.conf"
    if [[ -f "$kitty_theme" ]] && grep -Fq 'Auto-generated by drift wallpaper theming system' "$kitty_theme" 2>/dev/null; then
        [[ -L "$kitty_link" && "$(readlink "$kitty_link" 2>/dev/null || true)" == "theme.conf" ]] && rm -f "$kitty_link"
        rm -f "$kitty_theme"
        uninstall_restore_backup_path "kitty/theme.conf" 2>/dev/null || true
        uninstall_restore_backup_path "kitty/current-theme.conf" 2>/dev/null || true
    fi

    local foot_colors foot_colors_rel
    for foot_colors_rel in "foot/lunana-colors.ini" "foot/colors.ini"; do
        foot_colors="${XDG_CONFIG_HOME}/${foot_colors_rel}"
        if [[ -f "$foot_colors" ]] && grep -Fq 'Auto-generated by drift wallpaper theming system' "$foot_colors" 2>/dev/null; then
            rm -f "$foot_colors"
            uninstall_restore_backup_path "$foot_colors_rel" 2>/dev/null || true
        fi
    done

    if [[ $restored -eq 0 ]]; then
        tui_info "No pre-Lunana exact-file backups were found"
    else
        tui_success "Restored $restored pre-Lunana config(s)"
    fi
    [[ -d "$BACKUP_DIR" ]] && echo -e "  ${STY_FAINT}Original install backup: $BACKUP_DIR${STY_RST}"
    tui_section_end
}

uninstall_create_backup() {
    local backup_dir="${HOME}/.local/share/lunana-uninstall-backup-$(date +%Y%m%d-%H%M%S)"

    tui_info "Creating backup before uninstall..." >&2
    mkdir -p "$backup_dir"

    # Backup Lunana-specific files
    if [[ -d "${XDG_CONFIG_HOME}/quickshell/lunana" ]]; then
        cp -r "${XDG_CONFIG_HOME}/quickshell/lunana" "$backup_dir/quickshell-lunana"
    fi

    if [[ -d "${LUNANA_CONFIG_DIR}" ]]; then
        cp -r "${LUNANA_CONFIG_DIR}" "$backup_dir/$(basename "$LUNANA_CONFIG_DIR")"
    fi

    # Backup niri config
    if [[ -f "${XDG_CONFIG_HOME}/niri/config.kdl" ]]; then
        cp "${XDG_CONFIG_HOME}/niri/config.kdl" "$backup_dir/"
    fi

    # Backup user state
    if [[ -d "${XDG_STATE_HOME}/quickshell/user" ]]; then
        cp -r "${XDG_STATE_HOME}/quickshell/user" "$backup_dir/quickshell-state"
    fi

    uninstall_backup_restorable_configs "$backup_dir"
    uninstall_backup_shell_integration "$backup_dir"

    tui_success "Backup created: $backup_dir" >&2
    echo "$backup_dir"
}

uninstall_remove_lunana_only() {
    local removed=0
    local _start=$SECONDS

    tui_info "Removing Lunana-exclusive files..."
    echo ""

    # Pre-count existing items for N/M progress display
    local total=0
    for path in "${!LUNANA_ONLY_PATHS[@]}"; do
        local ep
        ep=$(eval echo "$path")
        [[ -e "$ep" ]] && ((total++))
    done

    if [[ $total -eq 0 ]]; then
        echo -e "  ${STY_FAINT}Nothing to remove — already clean.${STY_RST}"
    else
        local idx=0
        for path in "${!LUNANA_ONLY_PATHS[@]}"; do
            local ep
            ep=$(eval echo "$path")
            local desc="${LUNANA_ONLY_PATHS[$path]}"

            if [[ -d "$ep" ]]; then
                ((idx++))
                rm -rf "$ep"
                echo -e "  ${STY_FAINT}[$idx/$total]${STY_RST} ${STY_RED}✗${STY_RST} Removed: $desc"
                ((removed++))
            elif [[ -f "$ep" ]]; then
                ((idx++))
                rm -f "$ep"
                echo -e "  ${STY_FAINT}[$idx/$total]${STY_RST} ${STY_RED}✗${STY_RST} Removed: $desc"
                ((removed++))
            fi
        done
    fi

    # Clean up empty quickshell directory only if no other configs exist
    if ! has_other_quickshell_configs; then
        rmdir "${XDG_CONFIG_HOME}/quickshell" 2>/dev/null || true
    fi

    echo ""
    local _elapsed=$(( SECONDS - _start ))
    tui_success "Removed $removed Lunana-exclusive item(s)  (${_elapsed}s)"
}

uninstall_handle_shared_configs() {
    local removed=0
    local kept=0
    local _start=$SECONDS

    echo ""
    tui_section_start "Shared configurations"
    echo ""
    echo -e "  ${STY_FAINT}These configs may be used by other applications.${STY_RST}"
    echo ""

    # ── Phase 1: pre-scan all existing shared paths ────────────────────────
    local -a _paths=()
    local -A _desc=() _rec=() _reason=() _level=()

    for path in "${!SHARED_PATHS[@]}"; do
        local ep
        ep=$(eval echo "$path")
        [[ ! -e "$ep" ]] && continue

        parse_shared_path_meta "${SHARED_PATHS[$path]}"
        local desc="$SHARED_DESC"
        local app_cmd="$SHARED_APP"
        local level="$SHARED_LEVEL"

        local app_installed=false
        [[ -n "$app_cmd" ]] && command -v "$app_cmd" &>/dev/null && app_installed=true

        local rec="keep"
        local reason=""

        case "$level" in
            essential)
                $app_installed \
                    && reason="app installed, essential" \
                    || reason="essential system config"
                ;;
            optional)
                if $app_installed; then
                    reason="app installed"
                elif config_was_user_modified "$ep"; then
                    reason="has custom changes"
                else
                    rec="remove"
                    reason="app not found, Lunana default"
                fi
                ;;
            lunana_default)
                rec="remove"
                reason="created by Lunana"
                ;;
        esac

        # Special niri override
        if [[ "$path" == *"niri"* ]]; then
            if is_running_niri_session; then
                rec="keep"
                reason="YOU ARE IN A NIRI SESSION!"
            elif niri_config_has_user_customizations; then
                rec="keep"
                reason="has your customizations"
            fi
        fi

        _paths+=("$ep")
        _desc["$ep"]="$desc"
        _rec["$ep"]="$rec"
        _reason["$ep"]="$reason"
        _level["$ep"]="$level"
    done

    if [[ ${#_paths[@]} -eq 0 ]]; then
        tui_info "No shared configs found (already clean)"
        tui_section_end
        return 0
    fi

    # ── Phase 2: summary overview ──────────────────────────────────────────
    local _keep_count=0
    local _remove_count=0
    for ep in "${_paths[@]}"; do
        [[ "${_rec[$ep]}" == "keep" ]] && ((_keep_count++)) || ((_remove_count++))
    done

    echo -e "  Found ${STY_BOLD}${#_paths[@]}${STY_RST} shared config(s):  ${STY_YELLOW}${_keep_count} keep${STY_RST}  ${STY_RED}${_remove_count} remove${STY_RST}  ${STY_FAINT}(recommended)${STY_RST}"
    echo ""

    for ep in "${_paths[@]}"; do
        local rec="${_rec[$ep]}"
        local reason="${_reason[$ep]}"
        local desc="${_desc[$ep]}"
        local reason_color="${STY_FAINT}"
        [[ "$reason" == *"SESSION"* ]] && reason_color="${STY_RED}"
        [[ "$reason" == *"custom"* || "$reason" == *"customiz"* ]] && reason_color="${STY_YELLOW}"
        [[ "$reason" == *"installed"* ]] && reason_color="${STY_GREEN}"
        if [[ "$rec" == "keep" ]]; then
            echo -e "  ${STY_YELLOW}⊘${STY_RST} ${STY_BOLD}$desc${STY_RST}  ${reason_color}($reason)${STY_RST}"
        else
            echo -e "  ${STY_RED}✗${STY_RST} ${STY_BOLD}$desc${STY_RST}  ${STY_FAINT}($reason)${STY_RST}"
        fi
        echo -e "    ${STY_FAINT}$ep${STY_RST}"
    done

    echo ""
    tui_divider

    # ── Phase 3: interactive decisions ────────────────────────────────────
    if $ask; then
        echo ""
        echo -e "  ${STY_FAINT}Press Enter to accept the recommendation, or choose the opposite action.${STY_RST}"
        echo ""

        local idx=0
        local total=${#_paths[@]}

        for ep in "${_paths[@]}"; do
            ((idx++))
            local desc="${_desc[$ep]}"
            local rec="${_rec[$ep]}"
            local reason="${_reason[$ep]}"
            local reason_color="${STY_FAINT}"
            [[ "$reason" == *"SESSION"* ]] && reason_color="${STY_RED}"
            [[ "$reason" == *"custom"* || "$reason" == *"customiz"* ]] && reason_color="${STY_YELLOW}"
            [[ "$reason" == *"installed"* ]] && reason_color="${STY_GREEN}"

            echo -e "  ${STY_FAINT}[$idx/$total]${STY_RST} ${STY_CYAN}${STY_BOLD}${desc}${STY_RST}"
            echo -e "    ${reason_color}${reason}${STY_RST}"
            echo -e "    ${STY_FAINT}${ep}${STY_RST}"
            echo ""

            local user_wants_keep
            if [[ "$rec" == "keep" ]]; then
                if tui_confirm "    Keep this config?" "yes"; then
                    user_wants_keep=true
                else
                    user_wants_keep=false
                fi
            else
                if tui_confirm "    Remove this config?" "yes"; then
                    user_wants_keep=false
                else
                    user_wants_keep=true
                fi
            fi

            if $user_wants_keep; then
                echo -e "    ${STY_YELLOW}⊘${STY_RST} Keeping"
                ((kept++))
            else
                if [[ -d "$ep" ]]; then
                    rm -rf "$ep"
                else
                    rm -f "$ep"
                fi
                echo -e "    ${STY_RED}✗${STY_RST} Removed"
                ((removed++))
            fi
            echo ""
        done

    else
        # Non-interactive: apply recommendations strictly
        for ep in "${_paths[@]}"; do
            local desc="${_desc[$ep]}"
            local rec="${_rec[$ep]}"
            local reason="${_reason[$ep]}"
            local level="${_level[$ep]}"
            if [[ "$level" == "lunana_default" ]]; then
                [[ -d "$ep" ]] && rm -rf "$ep" || rm -f "$ep"
                echo -e "  ${STY_RED}✗${STY_RST} Removed: $desc ($reason)"
                ((removed++))
            else
                echo -e "  ${STY_YELLOW}⊘${STY_RST} Keeping: $desc ($reason)"
                ((kept++))
            fi
        done
    fi

    local _elapsed=$(( SECONDS - _start ))
    echo ""
    tui_info "Shared configs: ${removed} removed, ${kept} kept  (${_elapsed}s)"
    tui_section_end
}

uninstall_handle_quickshell_shared() {
    echo ""
    tui_section_start "Quickshell shared resources"
    echo ""

    # Check if other quickshell configs exist
    if has_other_quickshell_configs; then
        tui_warn "Other Quickshell configurations detected — keeping shared resources."
        echo ""
        for path in "${!QUICKSHELL_SHARED[@]}"; do
            local ep
            ep=$(eval echo "$path")
            local desc="${QUICKSHELL_SHARED[$path]}"
            [[ -e "$ep" ]] && echo -e "  ${STY_YELLOW}⊘${STY_RST} Keeping: $desc"
        done
    else
        echo -e "  ${STY_FAINT}No other Quickshell configs found.${STY_RST}"
        echo ""

        if $ask && tui_confirm "  Remove Quickshell shared resources (venv, themes)?" "yes"; then
            local _removed=0
            for path in "${!QUICKSHELL_SHARED[@]}"; do
                local ep
                ep=$(eval echo "$path")
                local desc="${QUICKSHELL_SHARED[$path]}"
                if [[ -d "$ep" ]]; then
                    rm -rf "$ep"
                    echo -e "  ${STY_RED}✗${STY_RST} Removed: $desc"
                    ((_removed++))
                elif [[ -f "$ep" ]]; then
                    rm -f "$ep"
                    echo -e "  ${STY_RED}✗${STY_RST} Removed: $desc"
                    ((_removed++))
                fi
            done
            # Clean up empty state directory
            rmdir "${XDG_STATE_HOME}/quickshell" 2>/dev/null || true
            rmdir "${XDG_CACHE_HOME}/quickshell" 2>/dev/null || true
            echo ""
            tui_success "Removed $_removed shared resource(s)"
        else
            for path in "${!QUICKSHELL_SHARED[@]}"; do
                local ep
                ep=$(eval echo "$path")
                local desc="${QUICKSHELL_SHARED[$path]}"
                [[ -e "$ep" ]] && echo -e "  ${STY_YELLOW}⊘${STY_RST} Keeping: $desc"
            done
        fi
    fi
    tui_section_end
}

uninstall_show_manual_steps() {
    echo ""
    tui_subtitle "Manual cleanup (optional)"
    echo ""
    echo -e "${STY_FAINT}These system changes were made during install.${STY_RST}"
    echo -e "${STY_FAINT}They may be used by other apps - only remove if not needed:${STY_RST}"
    echo ""

    echo -e "  ${STY_YELLOW}•${STY_RST} User groups: video, i2c, input"
    echo -e "    ${STY_FAINT}Used by: screen brightness, DDC monitor control, input devices${STY_RST}"
    echo ""
    echo -e "  ${STY_YELLOW}•${STY_RST} i2c-dev module: /etc/modules-load.d/i2c-dev.conf"
    echo -e "    ${STY_FAINT}Used by: ddcutil (external monitor brightness)${STY_RST}"
    echo ""
    echo -e "  ${STY_YELLOW}•${STY_RST} ydotool service"
    echo -e "    ${STY_FAINT}Used by: automation tools, some Wayland apps${STY_RST}"
    echo ""
    echo -e "  ${STY_YELLOW}•${STY_RST} SDDM theme: /usr/share/sddm/themes/drift-pixel"
    echo -e "    ${STY_FAINT}Used by: SDDM login screen${STY_RST}"
    echo ""
    echo -e "  ${STY_YELLOW}•${STY_RST} SDDM theme drop-in: /etc/sddm.conf.d/99-lunana-theme.conf"
    echo -e "    ${STY_FAINT}Used by: sets Current=drift-pixel (legacy path: /etc/sddm.conf.d/lunana-theme.conf)${STY_RST}"
    if [[ -f /etc/sddm.conf.d/98-lunana-greeter.conf ]]; then
        echo -e "  ${STY_YELLOW}•${STY_RST} SDDM greeter drop-in: /etc/sddm.conf.d/98-lunana-greeter.conf"
        echo -e "    ${STY_FAINT}Used by: login screen on Wayland with Niri (/usr/share/lunana/sddm/niri-greeter.kdl)${STY_RST}"
    fi
    echo ""

    if $ask && tui_confirm "Show commands to revert these changes?" "no"; then
        echo ""
        echo -e "  ${STY_CYAN}# Remove user from i2c group${STY_RST}"
        echo -e "  sudo gpasswd -d \$(whoami) i2c"
        echo ""
        echo -e "  ${STY_CYAN}# Remove i2c module autoload${STY_RST}"
        echo -e "  sudo rm /etc/modules-load.d/i2c-dev.conf"
        echo ""
        if has_usable_systemd_user_manager; then
            echo -e "  ${STY_CYAN}# Disable ydotool${STY_RST}"
            echo -e "  systemctl --user disable ydotool"
        elif command -v sv &>/dev/null; then
            echo -e "  ${STY_CYAN}# Disable ydotool user service${STY_RST}"
            echo -e "  sv down ~/.config/service/ydotool"
        fi
        echo ""
        echo -e "  ${STY_CYAN}# Remove SDDM theme${STY_RST}"
        echo -e "  sudo rm -rf /usr/share/sddm/themes/drift-pixel"
        echo ""
        echo -e "  ${STY_CYAN}# Remove SDDM theme config drop-in${STY_RST}"
        echo -e "  sudo rm -f /etc/sddm.conf.d/99-lunana-theme.conf /etc/sddm.conf.d/lunana-theme.conf"
        if [[ -f /etc/sddm.conf.d/98-lunana-greeter.conf ]]; then
            echo -e "  ${STY_CYAN}# Put the login screen back on the distribution's display server${STY_RST}"
            echo -e "  sudo rm -f /etc/sddm.conf.d/98-lunana-greeter.conf && sudo rm -rf /usr/share/lunana/sddm"
        fi
        echo ""
    fi
}

uninstall_show_packages() {
    echo ""
    tui_subtitle "Installed packages"
    echo ""
    echo -e "${STY_FAINT}Lunana may have installed these packages. Review before removing.${STY_RST}"
    echo ""

    # Detect distro
    local distro="${OS_GROUP_ID:-unknown}"
    [[ -z "$distro" || "$distro" == "unknown" ]] && detect_distro 2>/dev/null

    # Categorize packages by safety
    local safe_to_remove=()
    local ask_before_remove=()
    local keep_packages=()

    echo -e "${STY_CYAN}Package analysis:${STY_RST}"
    echo ""

    for cmd in "${!LUNANA_PACKAGES[@]}"; do
        # Skip if not installed
        command -v "$cmd" &>/dev/null || continue

        local meta="${LUNANA_PACKAGES[$cmd]}"
        IFS='|' read -r pkg_name pkg_desc pkg_usage <<< "$meta"
        
        local safety=$(get_package_removal_safety "$cmd")
        
        case "$safety" in
            safe)
                safe_to_remove+=("$pkg_name")
                echo -e "  ${STY_GREEN}✓${STY_RST} $pkg_name - $pkg_desc"
                echo -e "    ${STY_FAINT}Safe to remove (only used by Lunana)${STY_RST}"
                ;;
            ask)
                ask_before_remove+=("$pkg_name")
                echo -e "  ${STY_YELLOW}?${STY_RST} $pkg_name - $pkg_desc"
                echo -e "    ${STY_FAINT}May be used by other apps - check before removing${STY_RST}"
                ;;
            keep_qs)
                keep_packages+=("$pkg_name")
                echo -e "  ${STY_CYAN}⊘${STY_RST} $pkg_name - $pkg_desc"
                echo -e "    ${STY_YELLOW}KEEP: Other Quickshell configs detected${STY_RST}"
                ;;
            keep_session)
                keep_packages+=("$pkg_name")
                echo -e "  ${STY_RED}⊘${STY_RST} $pkg_name - $pkg_desc"
                echo -e "    ${STY_RED}KEEP: You are currently in a Niri session!${STY_RST}"
                ;;
            keep_user)
                keep_packages+=("$pkg_name")
                echo -e "  ${STY_CYAN}⊘${STY_RST} $pkg_name - $pkg_desc"
                echo -e "    ${STY_YELLOW}KEEP: Used by your system configuration${STY_RST}"
                ;;
            keep_deps)
                keep_packages+=("$pkg_name")
                echo -e "  ${STY_CYAN}⊘${STY_RST} $pkg_name - $pkg_desc"
                echo -e "    ${STY_YELLOW}KEEP: Required by other installed packages${STY_RST}"
                ;;
            *)
                ask_before_remove+=("$pkg_name")
                echo -e "  ${STY_YELLOW}?${STY_RST} $pkg_name - $pkg_desc"
                echo -e "    ${STY_FAINT}Unknown usage - check before removing${STY_RST}"
                ;;
        esac
    done

    echo ""
    
    # Show removal commands based on distro
    if [[ ${#safe_to_remove[@]} -gt 0 || ${#ask_before_remove[@]} -gt 0 ]]; then
        echo -e "${STY_CYAN}Removal commands:${STY_RST}"
        echo ""
        
        case "$distro" in
            arch)
                if [[ ${#safe_to_remove[@]} -gt 0 ]]; then
                    echo -e "  ${STY_GREEN}# Safe to remove:${STY_RST}"
                    echo -e "  yay -R ${safe_to_remove[*]}"
                    echo ""
                fi
                if [[ ${#ask_before_remove[@]} -gt 0 ]]; then
                    echo -e "  ${STY_YELLOW}# Check before removing:${STY_RST}"
                    echo -e "  # yay -R ${ask_before_remove[*]}"
                    echo ""
                fi
                ;;
            fedora)
                if [[ ${#safe_to_remove[@]} -gt 0 ]]; then
                    echo -e "  ${STY_GREEN}# Safe to remove:${STY_RST}"
                    echo -e "  sudo dnf remove ${safe_to_remove[*]}"
                    echo ""
                fi
                if [[ ${#ask_before_remove[@]} -gt 0 ]]; then
                    echo -e "  ${STY_YELLOW}# Check before removing:${STY_RST}"
                    echo -e "  # sudo dnf remove ${ask_before_remove[*]}"
                    echo ""
                fi
                echo -e "  ${STY_FAINT}# To disable COPRs:${STY_RST}"
                echo -e "  sudo dnf copr disable errornointernet/quickshell"
                echo -e "  sudo dnf copr disable yalter/niri"
                echo ""
                ;;
            debian|ubuntu)
                if [[ ${#safe_to_remove[@]} -gt 0 ]]; then
                    echo -e "  ${STY_GREEN}# Safe to remove:${STY_RST}"
                    echo -e "  sudo apt remove ${safe_to_remove[*]}"
                    echo ""
                fi
                if [[ ${#ask_before_remove[@]} -gt 0 ]]; then
                    echo -e "  ${STY_YELLOW}# Check before removing:${STY_RST}"
                    echo -e "  # sudo apt remove ${ask_before_remove[*]}"
                    echo ""
                fi
                echo -e "  ${STY_FAINT}# Compiled packages (in /usr/local/bin):${STY_RST}"
                echo -e "  # sudo rm /usr/local/bin/qs"
                echo -e "  # sudo rm /usr/local/bin/niri"
                echo ""
                ;;
            void)
                if [[ ${#safe_to_remove[@]} -gt 0 ]]; then
                    echo -e "  ${STY_GREEN}# Safe to remove:${STY_RST}"
                    echo -e "  sudo xbps-remove -R ${safe_to_remove[*]}"
                    echo ""
                fi
                if [[ ${#ask_before_remove[@]} -gt 0 ]]; then
                    echo -e "  ${STY_YELLOW}# Check before removing:${STY_RST}"
                    echo -e "  # sudo xbps-remove -R ${ask_before_remove[*]}"
                    echo ""
                fi
                ;;
            *)
                echo -e "${STY_FAINT}Remove packages using your package manager.${STY_RST}"
                echo -e "${STY_FAINT}Check ~/.cargo/bin and ~/go/bin for tools installed there.${STY_RST}"
                echo ""
                ;;
        esac
    fi

    if [[ ${#keep_packages[@]} -gt 0 ]]; then
        echo -e "${STY_YELLOW}Packages marked KEEP should not be removed:${STY_RST}"
        echo -e "  ${keep_packages[*]}"
        echo ""
    fi

    case "$distro" in
        void) echo -e "${STY_FAINT}Tip: Run 'xbps-query -X <package>' to see reverse dependencies.${STY_RST}" ;;
        arch) echo -e "${STY_FAINT}Tip: Run 'pacman -Qi <package>' to inspect package dependencies.${STY_RST}" ;;
        debian|ubuntu) echo -e "${STY_FAINT}Tip: Run 'apt-cache rdepends <package>' to see reverse dependencies.${STY_RST}" ;;
        *) echo -e "${STY_FAINT}Review reverse dependencies with your package manager before removing shared tools.${STY_RST}" ;;
    esac
    echo ""
}

###############################################################################
# Main uninstall flow
###############################################################################

run_uninstall() {
    local _uninstall_start=$SECONDS
    local installed_mode
    local update_strategy
    local package_name
    echo ""
    tui_title "Lunana Uninstaller"
    echo ""

    # Safety: if no TTY available, force non-interactive safe mode
    # This prevents catastrophic removal when piped or run via SSH
    if $ask && ! tty -s 2>/dev/null; then
        echo -e "${STY_YELLOW}No interactive terminal detected — using safe mode${STY_RST}"
        echo -e "${STY_FAINT}(All shared configs will be preserved. Use -y flag for non-interactive uninstall.)${STY_RST}"
        echo ""
        ask=false
    fi

    # Check if installed
    if [[ ! -f "${LUNANA_CONFIG_DIR}/installed_true" ]] && \
       [[ ! -d "${XDG_CONFIG_HOME}/quickshell/lunana" ]] && \
       [[ ! -f "${LUNANA_CONFIG_DIR}/version.json" ]] && \
       [[ ! -f "${XDG_BIN_HOME}/lunana" ]]; then
        tui_warn "Lunana does not appear to be installed"
        return 1
    fi

    # Detect distro for package info
    detect_distro 2>/dev/null || true
    installed_mode=$(get_installed_install_mode)
    update_strategy=$(get_installed_update_strategy)
    package_name=$(get_installed_package_name)

    # Check for critical conditions
    local warnings=()
    
    if is_running_niri_session; then
        warnings+=("You are currently running a Niri session")
    fi
    
    if has_other_quickshell_configs; then
        warnings+=("Other Quickshell configurations detected")
    fi

    if [[ "$update_strategy" == "package-manager" ]]; then
        if [[ -n "$package_name" ]]; then
            warnings+=("Shell payload is externally managed by package: ${package_name}")
        else
            warnings+=("Shell payload is externally managed by your package manager")
        fi
    fi

    # Warning
    echo -e "${STY_RED}${STY_BOLD}⚠ WARNING${STY_RST}"
    echo ""
    echo "This will remove Lunana from your system."
    echo ""
    
    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo -e "${STY_YELLOW}Important notices:${STY_RST}"
        for warn in "${warnings[@]}"; do
            echo -e "  ${STY_YELLOW}•${STY_RST} $warn"
        done
        echo ""
    fi
    
    echo -e "${STY_FAINT}What will happen:${STY_RST}"
    echo "  • Lunana shell configuration will be removed"
    if is_running_niri_session; then
        echo -e "  • ${STY_YELLOW}Your Niri session will continue (without the shell UI)${STY_RST}"
        echo -e "  • ${STY_YELLOW}Niri config will be preserved (you're using it!)${STY_RST}"
    else
        echo "  • Shared configs will be preserved unless you choose to remove them"
    fi
    if [[ "$update_strategy" == "package-manager" ]]; then
        echo "  • Externally managed shell packages will NOT be removed automatically"
        if [[ -n "$package_name" ]]; then
            echo "  • Remove package-managed payload separately: $package_name"
        fi
    else
        echo "  • System packages will NOT be removed automatically"
    fi
    echo ""

    # Confirm — in non-interactive mode (-y), skip confirmation
    if $ask; then
        if ! tui_confirm "Continue with uninstall?" "no"; then
            echo "Cancelled."
            return 0
        fi
    else
        echo -e "${STY_CYAN}Non-interactive mode: proceeding with safe uninstall...${STY_RST}"
    fi

    echo ""
    tui_divider
    echo ""

    # Create backup first
    local backup_dir
    backup_dir=$(uninstall_create_backup)

    # Stop services
    uninstall_stop_services

    # Remove Lunana-exclusive files (always safe)
    uninstall_remove_lunana_only
    uninstall_reload_user_systemd

    uninstall_restore_preinstall_configs
    uninstall_remove_shell_integration || tui_warn "Could not fully remove shell profile integration"

    # Handle shared configs (ask user)
    uninstall_handle_shared_configs

    # Handle quickshell shared resources
    uninstall_handle_quickshell_shared

    # Show manual steps (interactive only — don't overwhelm non-interactive output)
    if $ask; then
        uninstall_show_manual_steps
        uninstall_show_packages
    else
        echo ""
        echo -e "${STY_FAINT}Run './setup uninstall' interactively for package removal guidance.${STY_RST}"
    fi

    # Final message
    echo ""
    tui_divider
    echo ""

    printf "${STY_GREEN}${STY_BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                  ✓ Uninstall Complete                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    printf "${STY_RST}"
    echo ""

    echo -e "${STY_CYAN}Safety backup from just before uninstall:${STY_RST}"
    echo -e "  $backup_dir"
    if [[ -d "$BACKUP_DIR" ]]; then
        echo -e "${STY_CYAN}Original pre-install backup:${STY_RST}"
        echo -e "  $BACKUP_DIR"
    fi
    echo ""
    echo -e "${STY_FAINT}To restore from backup:${STY_RST}"
    echo -e "  cp -r $backup_dir/quickshell-lunana ${XDG_CONFIG_HOME}/quickshell/lunana"
    echo ""
    local _total_elapsed=$(( SECONDS - _uninstall_start ))
    echo -e "${STY_FAINT}To reinstall Lunana:${STY_RST}"
    echo -e "  git clone https://github.com/snowarch/inir.git && cd lunana && ./setup install"
    echo ""
    echo -e "${STY_FAINT}Total time: ${_total_elapsed}s${STY_RST}"
    echo ""
}

###############################################################################
# Quick uninstall (non-interactive, safe defaults)
###############################################################################

run_uninstall_quick() {
    echo ""
    tui_title "Lunana Quick Uninstall"
    echo ""

    echo -e "${STY_YELLOW}Quick uninstall will:${STY_RST}"
    echo "  • Remove Lunana-exclusive files only"
    echo "  • Keep all shared configs (Niri, themes, etc.)"
    echo "  • Keep all system packages"
    echo "  • Create a backup first"
    echo ""

    if ! tui_confirm "Continue?" "no"; then
        echo "Cancelled."
        return 0
    fi

    # Backup
    local backup_dir
    backup_dir=$(uninstall_create_backup)

    # Stop services
    uninstall_stop_services

    # Remove only Lunana-exclusive files
    ask=false  # Disable prompts for shared configs
    uninstall_remove_lunana_only
    uninstall_reload_user_systemd
    uninstall_restore_preinstall_configs
    uninstall_remove_shell_integration || tui_warn "Could not fully remove shell profile integration"

    echo ""
    tui_success "Lunana removed. All shared configs and packages preserved."
    echo ""
    echo -e "${STY_CYAN}Backup:${STY_RST} $backup_dir"
    echo ""
}
