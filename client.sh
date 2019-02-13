#!/bin/bash

PROJ_CMD_PATH="consul"
PROJ_CONFIG_DIRECTORY="consul.d/client"
PROJ_LOG_FILE="consul.log"
PROJ_DAEMON_RUNNABLE="true"

quiet_cd() {
  cd "$@" >/dev/null || return
}

SHELL_FILE_DIRECTORY="$(quiet_cd "${0%/*}/" && pwd -P)"

PROJ_PREFIX="$SHELL_FILE_DIRECTORY"

FILTERED_ENV=()
# Filter all but the specific variables.
for VAR in "${!PROJ_@}" "${!TRAVIS_@}"
do
  # Skip if variable value is empty.
  [[ -z "${!VAR}" ]] && continue

  FILTERED_ENV+=( "${VAR}=${!VAR}" )
done

exec /usr/bin/env -i "${FILTERED_ENV[@]}" /bin/bash "${SHELL_FILE_DIRECTORY}/homeskel/bin/skel" "$@"
