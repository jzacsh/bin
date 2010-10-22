#!/bin/bash
# taken from a bird

[[ $(pgrep "offlineimap") ]] && exit 1

offlineimap -o -u Noninteractive.Quiet # &>/dev/null
exit 0
