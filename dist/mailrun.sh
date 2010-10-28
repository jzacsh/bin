#!/bin/bash

[[ $(pgrep "offlineimap") ]] && exit 2

offlineimap -o -u Noninteractive.Quiet # &>/dev/null
exit 0
