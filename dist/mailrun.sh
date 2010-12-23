#!/bin/bash
[[ $(pgrep "offlineimap") ]] && pkill offlineimap || offlineimap -o -u Noninteractive.Quiet # &>/dev/null
