#!/usr/bin/env bash
#
# Cron job to thinly wrap restic, given RESTIC_PASSWORD (eg: set atop crontab).
set -euo pipefail

this="$(readlink -f "${BASH_SOURCE[0]}")"; declare -r this
exeName="$(basename "$this")"
log() {
  local lvl="$1"
  local msg="$2"
  shift 2

  local prefix
  printf -v prefix -- \
    '[%s %s] %s: ' \
    "$exeName" "$(date --iso-8601=s)" "$lvl"

  printf "$prefix""$msg" "$*"
}

log INFO 'starting\n'

# Noisy, meticulous functions to DRY up this script
#
cleanup() {
  log INFO 'cleaning up PID file: "%s"\n' "$pidFile"
  [[ "${pidFile:-x}" = x ]] || echo -n > "$pidFile"
}
isReadableFile() { [[ "${1:-x}" != x && -r "$1" && -f "$1" ]]; }
isNonemptyReadable() { isReadableFile "$1" && [[ -n "$(< "$1")" ]]; }
isPidAlive() { isNonemptyReadable "$1" && kill -0 "$(< "$1")" >/dev/null 2>&1; }
fail() {
  local failWith=1
  if [[ "$#" -gt 1 ]]; then
    failWith=$1; shift
  fi

  cleanup

  log FATAL '%s\n' "$*" >&2

  exit $failWith
}

# safe-to modify options: #############################
declare -r resticExec="$HOME"/media/src/restic/bin/restic
declare -r repo="$HOME"/back/local/restic
declare -r excludeFile="$HOME"/.config/restic-exclude
declare -r target="$HOME"
#######################################################

export TMPDIR=/tmp/

[[ "${resticExec:-x}" != x && -x "$resticExec" ]] ||
  fail 1 "path to restic, '$resticExec', not executable"

######################################
# Deal with previously running backups
#
declare -r dataDir="${XDG_DATA_HOME:-$HOME/.local/share}"
[[ "${dataDir:-x}" != x && -d "$dataDir" && -w "$dataDir" ]] ||
  fail 2 'No $XDG_DATA_HOME to store PID in'

printf -v pidFile '%s/%s.pid' "$dataDir" "$exeName"
isPidAlive "$pidFile" &&
  fail 3 "previous backup (PID=$(< "$pidFile")) still running"

# see comment thread in https://superuser.com/q/1228940/748767
log WARN 'either update to sysrestic or update PID file logic w/flock\n' >&2

##############################################################
# We're definitely backing up now, so register cleanup and PID
#
printf '%d' "$$" > "$pidFile" # record this backup's PID
trap cleanup SIGINT

[[ "${repo:-x}" != x && -w "$repo" && -d "$repo" ]] ||
  fail 4 "restic '$repo' not a writable directory"

isNonemptyReadable "$excludeFile" ||
  fail 5 "expected non-empty, readable exclude-file: '$excludeFile'"

[[ "${target:-x}" != x && -r "$target" && -d "$target" ]] ||
  fail 6 "backup target, '$target', not readable"

#########################
# Finally, run the backup
#
"$resticExec" version
time {
  set -x
  "$resticExec" \
    backup \
    --repo "$repo" \
    --one-file-system \
    --exclude-file "$excludeFile" \
    "$target"
  backupExited=$?
  set +x
}

if (( backupExited ));then
  fail 7 'backup failed; `restic backup` exited %d\n' $backupExited
fi

log INFO 'repo size per `du -sh` is now: %s\n' "$(du -sh "$repo")"

log INFO 'cleaning up old backups...\n'
time {
  set -x
  "$resticExec" \
    forget \
    --repo "$repo" \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 18
  forgetExited=$?
  set +x
}

if (( forgetExited ));then
  fail 8 \
    'Cleaning old backups failed; `restic forget` exited %d\n' $forgetExited
fi

cleanup
