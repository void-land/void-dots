#!/bin/bash

# umu-launcher-lib.sh — Reusable UMU Launcher library
# Source this file; do not execute it directly.

# Guard against being executed instead of sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
   echo "ERROR: umu-launcher-lib.sh must be sourced, not executed." >&2
   exit 1
fi

#------------------------------------------
# UI & Logging Helpers
#------------------------------------------
_UMU_RED='\033[0;31m'
_UMU_GREEN='\033[0;32m'
_UMU_YELLOW='\033[1;33m'
_UMU_BLUE='\033[0;34m'
_UMU_NC='\033[0m'

umu_log()   { echo -e "${_UMU_GREEN}[$(date '+%H:%M:%S')]${_UMU_NC} $1"; }
umu_error() { echo -e "${_UMU_RED}[ERROR]${_UMU_NC} $1" >&2; }
umu_warn()  { echo -e "${_UMU_YELLOW}[WARN]${_UMU_NC} $1"; }
umu_info()  { echo -e "${_UMU_BLUE}[INFO]${_UMU_NC} $1"; }

#------------------------------------------
# Internal Cleanup Logic
#------------------------------------------
_umu_cleanup() {
   local exit_code=$?
   if [[ -n "$_UMU_CLEANUP_DONE" ]]; then
      return
   fi
   _UMU_CLEANUP_DONE=1

   echo ""
   umu_log "Shutting down..."

   if [[ -n "$SYSTEMD_UNIT" ]] && systemctl --user is-active --quiet "$SYSTEMD_UNIT.scope" 2>/dev/null; then
      echo ""
      echo -e "${_UMU_YELLOW}Process tree before cleanup:${_UMU_NC}"
      systemctl --user status "$SYSTEMD_UNIT.scope" --no-pager 2>/dev/null | grep -E "├─|└─" || echo "  (no process tree)"
      echo ""

      umu_log "Force stopping systemd scope..."
      systemctl --user kill --signal=SIGKILL "$SYSTEMD_UNIT.scope" 2>/dev/null
      systemctl --user stop "$SYSTEMD_UNIT.scope" 2>/dev/null
      systemctl --user reset-failed "$SYSTEMD_UNIT.scope" 2>/dev/null
   fi

   umu_log "Cleanup complete. Exit code: $exit_code"
   exit "$exit_code"
}

# Registered as soon as this file is sourced — harmless even before any
# game-specific variables exist, since every reference inside the handler
# is guarded (empty SYSTEMD_UNIT just means there's nothing to clean up).
trap _umu_cleanup SIGINT SIGTERM SIGHUP EXIT

#------------------------------------------
# Core Execution Steps
#------------------------------------------
_umu_validate() {
   umu_log "Validating environment..."

   local required_vars=(GAME_DIR GAME_EXE WINE_PREFIX PROTONPATH)
   local var
   for var in "${required_vars[@]}"; do
      if [[ -z "${!var:-}" ]]; then
         umu_error "Required variable '$var' is not set. Define it before calling umu_launch_game."
         exit 1
      fi
   done

   if ! command -v systemctl &>/dev/null; then
      umu_error "systemctl not found. This script requires systemd."
      exit 1
   fi

   if ! command -v umu-run &>/dev/null; then
      umu_error "umu-run not found. Install your distribution's umu-launcher package."
      exit 1
   fi

   if [[ ! -f "$GAME_EXE" ]]; then
      umu_error "Game executable not found: $GAME_EXE"
      exit 1
   fi

   if [[ ! -d "$PROTONPATH" ]]; then
      umu_error "Proton not found at: $PROTONPATH"
      exit 1
   fi

   if command -v gamemoderun &>/dev/null; then
      umu_info "GameMode: Available"
      _PROTON_GAMEMODE=1
   else
      umu_warn "GameMode: Not found"
      _PROTON_GAMEMODE=0
   fi
}

_umu_setup_environment() {
   umu_log "Configuring environment..."

   # Core UMU variables
   export GAMEID="$GAMEID"
   export PROTONPATH="$PROTONPATH"
   export WINEPREFIX="$WINE_PREFIX"
   export STEAM_COMPAT_APP_ID="$STEAM_APP_ID"
   export UMU_RUNTIME_UPDATE=0
   export PROTON_USE_STEAM_STUB=0

   # Graphics caching — opt out per-game with: DXVK_STATE_CACHE_PATH="" umu_launch_game
   # export DXVK_STATE_CACHE_PATH="${DXVK_STATE_CACHE_PATH:-$WINE_PREFIX}"

   # MangoHud Configuration
   export MANGOHUD="${MANGOHUD:-1}"
   export MANGOHUD_CONFIG="${MANGOHUD_CONFIG:-full,vsync=1,font_size=16,font_scale=1.0}"

   # Logging
   export PROTON_LOG="${PROTON_LOG:-0}"
   export PROTON_LOG_DIR="${PROTON_LOG_DIR:-$GAME_DIR}"

   # GameMode
   export PROTON_GAMEMODE="$_PROTON_GAMEMODE"

   # Hook: a per-game script can define umu_env_hook() to set/override
   # additional env vars (e.g. DXVK_ASYNC, VKD3D_CONFIG) right before launch.
   if declare -f umu_env_hook &>/dev/null; then
      umu_info "Running game-specific env hook..."
      umu_env_hook
   fi

   umu_log "Environment configured"
}

_umu_launch_game() {
   umu_log "=========================================="
   umu_log "  Launching: $GAME_NAME"
   umu_log "=========================================="
   umu_log "Systemd Unit: $SYSTEMD_UNIT.scope"
   umu_log "Executable: $GAME_EXE"
   umu_log "Prefix: $WINE_PREFIX"
   umu_log "Proton: $PROTONPATH"
   if [[ "$PROTON_LOG" -eq 1 ]]; then
      umu_log "Proton log dir: $PROTON_LOG_DIR"
   fi
   umu_log "=========================================="

   local cmd="umu-run \"$GAME_EXE\" $GAME_ARGS"

   if [[ "$_PROTON_GAMEMODE" -eq 1 ]]; then
      cmd="gamemoderun $cmd"
      umu_log "Launching with GameMode..."
   else
      umu_log "Launching..."
   fi

   systemd-run --user --scope \
      --unit="$SYSTEMD_UNIT" \
      --description="UMU Game: $GAME_NAME" \
      --property=KillMode=control-group \
      --collect \
      bash -c "$cmd"

   GAME_EXIT_CODE=${PIPESTATUS[0]}

   umu_log "=========================================="
   umu_log "Game exited with code: $GAME_EXIT_CODE"

   if [[ $GAME_EXIT_CODE -ne 0 ]]; then
      umu_error "Game crashed! Check output above for errors like:"
      umu_error "  - err:seh:NtRaiseException (crash/exception)"
      umu_error "  - err:module:import_dll (missing DLLs)"
      umu_error "  - fixme:d3d/fixme:dxgi (graphics issues)"
   fi
   umu_log "=========================================="

   return "$GAME_EXIT_CODE"
}

#------------------------------------------
# Public Entrypoint Function
#------------------------------------------
umu_launch_game() {
   clear

   # Apply fallback defaults for optional variables if not explicitly set
   GAME_NAME="${GAME_NAME:-Unnamed Game}"
   GAMEID="${GAMEID:-umu-default}"
   STEAM_APP_ID="${STEAM_APP_ID:-0}"
   GAME_ARGS="${GAME_ARGS:-}"

   # Dynamically build systemd unit name using a safe string variant of the game ID
   # local safe_id
   # safe_id="$(echo "$GAMEID" | tr -cd '[:alnum:]_-')"
   export SYSTEMD_UNIT="game-umu-$(date +%s)"

   echo "=========================================="
   echo "  $GAME_NAME"
   echo "  UMU Launcher Library v2.1"
   echo "=========================================="
   echo ""

   _umu_validate
   _umu_setup_environment

   umu_log "Changing to game directory..."
   if ! cd "$GAME_DIR"; then
      umu_error "Failed to change directory to: $GAME_DIR"
      exit 1
   fi

   _umu_launch_game
}