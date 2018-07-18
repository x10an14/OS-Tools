#!/bin/sh

# jxq
# Ref. displaylink-debian/post-install-guide.md
xrandr --setprovideroutputsource 1 0
xrandr --setprovideroutputsource 2 0

xrandr \
    --output DP-1 --off \
    --output HDMI-2 --off \
    --output HDMI-1 --off \
    --output DVI-I-1-1 --mode 1920x1200 --pos 3120x0 --rotate left \
    --output DVI-I-2-2 --mode 1920x1200 --pos 0x0 --rotate left \
    --output eDP-1 --primary --mode 1920x1080 --pos 1200x840 --rotate normal
