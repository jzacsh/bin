#!/usr/bin/env bash
set -e
set -x

# config
gdriveRoot="$(readlink -f "$1")"
gdriveArt="$2"

[ -z "$gdriveArt" ] && { echo '$2 must be a subpath' >&2; exit 2; }

# sanity checks
fullPath="$(readlink -f "$gdriveRoot"/"$gdriveArt")"
[ -d "$fullPath" ] || {
  error='cannot find subdir in gdrive root:'\
    '\n\tgdrive: "%s"\n\tsubdir: "%s"\n\n'
  printf "$error" "$gdriveRoot" "$gdriveArt">&2
  exit 2
}

cd "$fullPath"

# step #1: update everything locally
skicka download "$gdriveArt" "$fullPath"

# step #2: update everything remotely
skicka upload "$fullPath" "$gdriveArt"

# step #3: update the index and upload it
gdriveindex.sh "$gdriveRoot"  "$gdriveArt"
