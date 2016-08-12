#!/usr/bin/env bash
#
# Updates an index listing, and entire related directory.
set -euo pipefail

die() (
  local msg="$1"; shift
  printf '['"$(date --iso-8601=s)"'] Error: '"$msg" "$@" >&2
  exit 1
)

declare -r dirtojson="$HOME/bin/share/dirtojson.js"
{ [ -f "$dirtojson" ] && [ -x "$dirtojson" ]; } ||
  die 'Cannot find `dirtojson` utility at:\n\t"%s"\n' "$dirtojson"

masterDir="$(
  readlink -f "$HOME/media/www/keycdn/content/art" ||
    die 'KeyCDN master dir ont where expected'
)"; declare -r masterDir
{ [ -d "$masterDir" ] && [ -w "$masterDir" ]; } ||
  die 'writeable, local master of CDN dir not found:\n\t"%s"\n' "$masterDir"

buildIndex() ( "$dirtojson" "$masterDir"; )

declare -r jsonIndex="$masterDir"/index.json
{ [ -f "$jsonIndex" ] && diff -u "$jsonIndex" <(buildIndex); } || {
  buildIndex> "$jsonIndex" ||
    die 'failed to build and save JSON index of files\n'
}

rsync \
    --verbose --delete --archive --acls --xattrs --recursive \
    "$masterDir"/.  \
    rsync.keycdn.com:zones/content/art/ ||
  die 'failed to rsync local art up to CDN\n'