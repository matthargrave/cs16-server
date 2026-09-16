#!/usr/bin/env bash
set -e


# Starts the server with the given parameters.
function start_server() {
    START_OPTIONS=("-game" "${GAME:-cstrike}")
    START_OPTIONS+=("+hostname" "\"${SERVER_NAME:-CS 1.6 Server}\"")
    START_OPTIONS+=("+map" "${MAP:-cs_assault}")
    START_OPTIONS+=("+maxplayers" "${MAXPLAYERS:-24}")
    START_OPTIONS+=("+sv_lan" "${SVLAN:-0}")
    if [ -z "${RESTART_ON_FAIL}" ]; then
        START_OPTIONS+=("-norestart")
    fi
    set -x
    "${HLDS_DIR}/hlds_run" "${START_OPTIONS[@]}" ${EXTRA_PARAMS}
}

declare -A server_config
start_server
