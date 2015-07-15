#!/usr/bin/env bash

findXdgDirsContents() {
  local xdgConfig="${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs"
  grep '^XDG_\w*_DIR=' "$xdgConfig" |
    sed -e 's|^XDG_\w*_DIR="\$HOME/\(.*\)\"$|\1|' |
    while read dir; do find ~/"$dir"/ -type f;done
}

hasXdgContent() { [[ -n "$(findXdgDirsContents)" ]]; }

isXdgEmpty() { ! hasXdgContent; }

if [[ "${BASH_SOURCE[0]}" = "$0" ]];then findXdgDirsContents; fi
