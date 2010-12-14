#!/bin/bash
pkill offlineimap
[[ $(pgrep "offlineimap") ]] || offlineimap -o -u Noninteractive.Quiet # &>/dev/null
