#!/bin/bash

[[ $(pgrep "offlineimap") ]] || offlineimap -o -u Noninteractive.Quiet # &>/dev/null
