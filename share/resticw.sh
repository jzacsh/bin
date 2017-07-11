#!/usr/bin/env bash
#
# Cron job to thinly wrap restic, given RESTIC_PASSWORD (eg: set atop crontab).
set -e
date --iso-8601=ns

# Noisy, meticulous functions to DRY up this script
#
cleanup() { [ -n "$pidFile" ] && echo -n > "$pidFile"; }
isReadableFile() { [ -n "$1" ] && [ -r "$1" ] && [ -f "$1" ]; }
isNonemptyReadable() { isReadableFile "$1" && [ -n "$(< "$1")" ]; }
isPidAlive() { isNonemptyReadable "$1" && kill -0 "$(< "$1")" >/dev/null 2>&1; }
fail() {
  local failWith=1
  if [ $# -gt 1 ]; then
    failWith=$1; shift
  fi

  printf 'ERROR:\t%s\n' "$*" >&2

  exit $failWith
}

##########################
# Start logging everything
#
set -x

# safe-to modify options: #############################
declare -r resticExec="$HOME"/media/src/restic/bin/restic
declare -r repo="$HOME"/back/local/restic
declare -r excludeFile="$HOME"/.config/restic-exclude
declare -r target="$HOME"
#######################################################

export TMPDIR=/tmp/

{ [ -n "$resticExec" ] && [ -x "$resticExec" ]; } ||
  fail 1 "Path to restic, '$resticExec', not executable"

######################################
# Deal with previously running backups
#
declare -r dataDir="${XDG_DATA_HOME:-$HOME/.local/share}"
{ [ -n "$dataDir" ] && [ -d "$dataDir" ] && [ -w "$dataDir" ]; } ||
  fail 2 'No $XDG_DATA_HOME to store PID in'
declare pidFile="$dataDir"/"$(basename "$(readlink -f "${BASH_SOURCE[0]}")")".pid
isPidAlive "$pidFile" &&
  fail 3 "previous backup (PID=$(< "$pidFile")) still running"

# see comment thread in https://superuser.com/q/1228940/748767
printf \
  'WARNING: either update to sysrestic or update PID file logic w/flock\n' >&2

##############################################################
# We're definitely backing up now, so register cleanup and PID
#
printf '%d' "$$" > "$pidFile" # record this backup's PID
trap cleanup SIGINT

{ [ -n "$repo" ] && [ -w "$repo" ] && [ -d "$repo" ]; } ||
  fail 4 "Restic '$repo' not a writable directory"

isNonemptyReadable "$excludeFile" ||
  fail 5 "expected non-empty, readable exclude-file: '$excludeFile'"

{ [ -n "$target" ] && [ -r "$target" ] && [ -d "$target" ]; } ||
  fail 6 "Backup target, '$target', not readable"

#########################
# Finally, run the backup
#
"$resticExec" version
time {
  "$resticExec" \
    backup \
    --repo "$repo" \
    --exclude-file "$excludeFile" \
    "$target"
  resticExited=$?
}
du -sh "$repo"

cleanup
date --iso-8601=ns
exit ${resticExited:-0}
