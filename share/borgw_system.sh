#!/usr/bin/env bash
#
# System backup script. Thinly wraps borgbackup, and expects $1 is a
# Expects
set -o errexit
set -o nounset
set -o pipefail

declare -r srcDir=/

# Edit ABOVE this line #######################
##############################################
die() (
  local msg="$1"; shift
  printf 'Error: '"$msg" "$@" >&2; exit 1
)
isWriteDir() ( [ -d "$1" ] || [ -w "$1" ]; )

[ $# -eq 1 ] || die '
  Usage: BACKUP_DISKDIR

  Such that a borg repo exists at BACKUP_DISKDIR/system/borg
' "$(basename "$0")"
declare -r machineRepoDir="$1"

[ "$EUID" -eq 0 ] || die 'MUST be run as root, but found $EUID=%s\n' "$EUID"

isWriteDir "$machineRepoDir" ||
  die 'Machine backups container not writeable dir:\n\t"%s"\n' "$machineRepoDir"

declare -r repoDir="$machineRepoDir"/system/borg
isWriteDir "$repoDir" ||
  die 'Path to repo dir not a writeable directory:\n\t"%s"\n' "$repoDir"

{ [ -d "$srcDir" ] && [ -r "$srcDir" ]; } ||
  die 'Source for backup is not a readable directory:\n\t"%s"\n' "$srcDir"

set -x
time (
  borg create \
    --debug --verbose --stats \
    "$repoDir"::'{hostname}-'"$(date --iso-8601=ns)" \
    "$srcDir" \
    --exclude '/dev/*' \
    --exclude '/proc/*' \
    --exclude '/sys/*' \
    --exclude '/tmp/*' \
    --exclude '/run/*' \
    --exclude '/mnt/*' \
    --exclude '/media/*' \
    --exclude '/lost+found' \
    --exclude '/home/*'   # home excluded because its backups run separtely

    # exclude paths, taken from https://wiki.archlinux.org/index.php/full_system_backup_with_rsync
) 2>&1 | tee -a "$machineRepoDir"/system.log
