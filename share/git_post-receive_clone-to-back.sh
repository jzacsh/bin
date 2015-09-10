#!/usr/bin/env bash
#
# Clones updated repo to relative mirror in ~/back/src/, assuming:
#   1. repo is a `--bare` git repo in ~/src/
#   2. a regular `clone` of it lives in ~/back/src/ with the same path
#
# For git API utilized in this script, see:
#   man 5 githooks | less +/^\ *post-receive
set -e
declare -r srcsRoot="$(readlink -f ~/src)"
declare -r clonesRoot="$(readlink -f ~/back/src)"

declare -r currentRoot="$(readlink -f "$PWD")"
declare -r repoRelative="${currentRoot/$srcsRoot}"
[ -e ~/src/"$repoRelative" ]  # sanity check


# defensive block... should happen just once, if ever
expectedCloneTo="${clonesRoot}${repoRelative}"
if [ ! -e "$expectedCloneTo" ];then
  mkdir -p "$expectedCloneTo"
  git clone --quiet "$currentRoot" "$expectedCloneTo"
fi
expectedCloneTo="$(readlink -f "$expectedCloneTo")"

printf 'Force-updating repo "%s" at "%s" ... ' "$repoRelative" "$expectedCloneTo"
git \
  --work-tree="$expectedCloneTo" \
  --git-dir="$currentRoot" \
  checkout --force
(( $? )) && echo 'Failed' || echo 'Done'
