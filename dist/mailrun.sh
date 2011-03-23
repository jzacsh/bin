#!/bin/bash
printf 'started:\t%s\n' "$(date --rfc-3339=seconds)"
[[ $(pgrep "offlineimap") ]] && pkill offlineimap || offlineimap -o -u Noninteractive.Quiet # &>/dev/null
printf 'ended:\t%s\n' "$(date --rfc-3339=seconds)"
