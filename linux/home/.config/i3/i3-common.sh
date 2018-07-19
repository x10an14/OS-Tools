#!/usr/bin/env bash

LOGFOLDER="$HOME/.config/i3/logs"

if [ ! -d "${LOGFOLDER}" ]; then
    mkdir "$(realpath -f "${LOGFOLDER}")"
fi
LOGFILE=$(basename "${0}")
LOGFILE="${LOGFOLDER}/${LOGFILE}.log"

