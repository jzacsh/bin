#!/usr/bin/env bash
#
# Utilizes skicka upload (but can use any 3rd-party cloud uploader) to keep an
# up to date index of a given directory  
#   Example args: $1=~/usr/share/drive/ $2=some/public/dir/
#
dieUsage() { printf 'usage: ~/gdrive/path subpath/to/index\n' >&2; exit 1; }

(( $# == 2 )) || dieUsage
localRoot="$(readlink -f "$1")"
drivePath="$2"

[[ -d "$localRoot"/"$drivePath" ]] || {
  logError $BEHAVIOR_EXIT_USAGE 'subpath/to/index must be a subdirectory'
  dieUsage
}

die() {
  local err="$1"; shift
  echo -e $@; cleanup; exit $err
}
cleanup() { if [ -n "$tmpJson" ];then rm -v "$tmpJson";fi }

set -e
trap cleanup ERR

fullPath="$(readlink -f "$localRoot"/"$drivePath")"
tmpJson="$(mktemp --tmpdir "$(basename "$0")-XXXXXX.json")"
dirtojson.js "$fullPath" > "$tmpJson"

if diff "$fullPath"/index.json "$tmpJson" >/dev/null 2>&1; then
  die 0 'index.json already up to date\n'
fi


cp -v "$tmpJson" "$fullPath"/index.json
pushd "$fullPath"
skicka upload ./index.json "$drivePath"
cleanup
