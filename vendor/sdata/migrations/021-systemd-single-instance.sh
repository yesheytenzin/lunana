#!/usr/bin/env bash

MIGRATION_ID="021-systemd-single-instance"
MIGRATION_TITLE="Move Lunana shell startup to a single systemd owner"
MIGRATION_DESCRIPTION="Removes compositor startup of lunana, installs/enables the user lunana.service, and keeps shell startup owned by a single systemd user unit."
MIGRATION_TARGET_FILE="~/.config/systemd/user/lunana.service + ~/.config/niri/config.d/50-startup.kdl"
MIGRATION_REQUIRED=true

# Source the predicate helper when migrations run outside the installer.
_migration_repo_root="${REPO_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=/dev/null
source "${_migration_repo_root}/sdata/lib/functions.sh" 2>/dev/null || true

migration_check() {
  # No-op if usable systemd user manager is not available (ADR-0002).
  # Without the predicate, systemctl --user can block for 10-30s.
  has_usable_systemd_user_manager || return 1

  local xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local startup_cfg="${xdg_config_home}/niri/config.d/50-startup.kdl"
  local monolithic_cfg="${xdg_config_home}/niri/config.kdl"
  local service_file="${xdg_config_home}/systemd/user/lunana.service"
  local startup_pattern='spawn-at-startup.*([^[:alnum:]_-]lunana([^[:alnum:]_/-]|$)|\.local/bin/lunana([^[:alnum:]_/-]|$)|config/quickshell/lunana/scripts/lunana([^[:alnum:]_/-]|$))'
  local runsvdir_pattern='spawn-sh-at-startup.*runsvdir'

  if [[ ! -f "$service_file" ]]; then
    return 0
  fi

  if [[ -f "$startup_cfg" ]] && grep -vE '^[[:space:]]*//' "$startup_cfg" 2>/dev/null | grep -Eq "$startup_pattern"; then
    return 0
  fi

  if [[ -f "$monolithic_cfg" ]] && grep -vE '^[[:space:]]*//' "$monolithic_cfg" 2>/dev/null | grep -Eq "$startup_pattern"; then
    return 0
  fi

  # Check for runsvdir entry that would cause double shell when systemd is usable
  if [[ -f "$startup_cfg" ]] && grep -vE '^[[:space:]]*//' "$startup_cfg" 2>/dev/null | grep -Eq "$runsvdir_pattern"; then
    return 0
  fi

  if [[ -f "$monolithic_cfg" ]] && grep -vE '^[[:space:]]*//' "$monolithic_cfg" 2>/dev/null | grep -Eq "$runsvdir_pattern"; then
    return 0
  fi

  if ! systemctl --user is-enabled --quiet lunana.service >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

migration_preview() {
  echo -e "${STY_RED}- spawn-at-startup \"lunana\" \"start\"${STY_RST}"
  echo -e "${STY_GREEN}+ systemd user service owns Lunana startup${STY_RST}"
  echo -e "${STY_GREEN}+ ~/.config/systemd/user/lunana.service enabled${STY_RST}"
  echo -e "${STY_RED}- spawn-sh-at-startup \"exec runsvdir ~/.config/service\"${STY_RST}"
}

migration_apply() {
  # No-op if usable systemd user manager is not available (ADR-0002).
  # Without the predicate, systemctl --user can block for 10-30s.
  has_usable_systemd_user_manager || return 0

  local xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local startup_cfg="${xdg_config_home}/niri/config.d/50-startup.kdl"
  local monolithic_cfg="${xdg_config_home}/niri/config.kdl"
  local service_file="${xdg_config_home}/systemd/user/lunana.service"
  local launcher_path="${XDG_BIN_HOME:-$HOME/.local/bin}/lunana"
  local systemd_user_dir="${xdg_config_home}/systemd/user"
  local service_asset
  local tmp_file

  _remove_lunana_startup_lines() {
    local file="$1"
    [[ -f "$file" ]] || return 0

    python3 - "$file" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
pattern = re.compile(r'^(?![ \t]*//).*spawn-at-startup.*(?:[^A-Za-z0-9_-]lunana(?![A-Za-z0-9_/-])|\.local/bin/lunana(?![A-Za-z0-9_/-])|config/quickshell/lunana/scripts/lunana(?![A-Za-z0-9_/-])).*\n?', re.MULTILINE)
new_text = pattern.sub('', text)
if new_text != text:
    path.write_text(new_text)
PY
  }

  _remove_runsvdir_lines() {
    local file="$1"
    [[ -f "$file" ]] || return 0

    python3 - "$file" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
pattern = re.compile(
    r'(?ms)^[ \t]*// BEGIN lunana-runsvdir-fallback\n'
    r'.*?^[ \t]*// END lunana-runsvdir-fallback\n?'
)
new_text = pattern.sub('', text)
pattern = re.compile(r'^(?![ \t]*//).*spawn-sh-at-startup.*runsvdir.*\n?', re.MULTILINE)
new_text = pattern.sub('', new_text)
if new_text != text:
    path.write_text(new_text)
PY
  }

  if [[ ! -f "$service_file" ]]; then
    service_asset="${REPO_ROOT}/assets/systemd/lunana.service"
    if [[ -f "$service_asset" ]]; then
      mkdir -p "$systemd_user_dir" || return 1
      mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}" || return 1
      tmp_file="${XDG_CACHE_HOME:-$HOME/.cache}/lunana.service.migration.$$"
      sed "s|^ExecStart=.*|ExecStart=${launcher_path//&/\\&} run --session|" "$service_asset" > "$tmp_file" \
        || { rm -f "$tmp_file"; return 1; }
      cp -f "$tmp_file" "$service_file" || { rm -f "$tmp_file"; return 1; }
      rm -f "$tmp_file"
    else
      return 1
    fi
  fi

  if [[ -f "$startup_cfg" ]]; then
    _remove_lunana_startup_lines "$startup_cfg" || return 1
    _remove_runsvdir_lines "$startup_cfg" || return 1
  fi

  if [[ -f "$monolithic_cfg" ]]; then
    _remove_lunana_startup_lines "$monolithic_cfg" || return 1
    _remove_runsvdir_lines "$monolithic_cfg" || return 1
  fi

  systemctl --user daemon-reload >/dev/null 2>&1 || return 1
  if ! systemctl --user is-enabled --quiet lunana.service >/dev/null 2>&1; then
    # Unit has no [Install] section: ownership is a compositor wants link.
    local compositor_unit=""
    if systemctl --user cat niri.service >/dev/null 2>&1; then
      compositor_unit="niri.service"
    elif systemctl --user cat 'wayland-wm@Hyprland.service' >/dev/null 2>&1; then
      compositor_unit="wayland-wm@Hyprland.service"
    fi
    [[ -n "$compositor_unit" ]] || return 1
    mkdir -p "$systemd_user_dir/${compositor_unit}.wants" || return 1
    ln -sf "$service_file" "$systemd_user_dir/${compositor_unit}.wants/lunana.service" || return 1
    systemctl --user daemon-reload >/dev/null 2>&1 || return 1
    systemctl --user is-enabled --quiet lunana.service >/dev/null 2>&1 || return 1
  fi
  if [[ -n "${NIRI_SOCKET:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    systemctl --user reset-failed lunana.service >/dev/null 2>&1 || return 1
    systemctl --user start lunana.service >/dev/null 2>&1 || return 1
  fi

  return 0
}
