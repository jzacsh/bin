#!/usr/bin/env bash
#
# see: https://bugs.launchpad.net/ubuntu/+source/xorg-server/+bug/287215
#

xmm() { /usr/bin/xmodmap -display :0 $@; }

xmm -pke | /bin/grep Caps_Lock >/dev/null 2>&1 || exit 0

xmm $HOME/.config/xmodmaprc
