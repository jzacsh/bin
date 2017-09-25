#!/usr/bin/env bash
#
# First-pass (most naiive implementation - zero thought given to computational
# complexity). Took 4 min. to run on 1.9G of 107k files -- about 50 git
# repositories.
set -euo pipefail

declare -r childrenOf="$(readlink -f "$1")"

declare -a children=()
while read dir; do children+=("$dir"); done
declare -r children
numDirs="${#children[@]}"; declare -r numDirs
printf "%d children's trees to check...\n" $numDirs

# takes $1=part $2=whole
# returns integer in [0,100]
percentProgress() (
  printf -- \
    'scale=2; (%s / %s) * 100\n' "$1" "$2" |
    bc | sed --expression 's|\..*$||'
)

printProgress() (
  local index=$1 total=$2
  printf '\r%3d%% [%4d of %4d] ' \
    $(percentProgress $index $total) \
    $index $total >&2
)

dumpTreeContentNewest() {
  find "$childrenOf" -mindepth 2 -printf "%T@\t%P\n" |
    sort --reverse --numeric-sort
# printf '[dbg: %s] done sorting\n' "$(date --iso-8601=ns)" >&2 # DO NOT SUBMIT
}

declare -a sorted=()
declare -A seen=()
while read stamp path;do
  rootName="$(echo "$path" | sed --expression 's|/.*$||g')"
# printf "[dbg] root: %s; seen before? '%s'...\n\tgiven:\t%s\n" \
#   "$rootName" "${seen["$rootName"]:-}" "$path" >&2 # DO NOT SUBMIT
  if [[ -n "${seen["$rootName"]:-}" ]];then continue; fi

  sorted+=("$rootName")
  seen["$rootName"]="$stamp"

  printProgress ${#sorted[@]} $numDirs >&2
done < <(dumpTreeContentNewest)
printf '\n' >&2

printf 'From most recent activity (first) to most stale...\n'
printf '%s, %s\n' \
  'most recent activity' 'directory'
for dir in "${sorted[@]}"; do
  stamp="${seen["$dir"]}"
  humanWhen="$(date --date=@"$stamp")"
  printf '%s\t%s\n' "$humanWhen" "$dir"
done
