#!/bin/bash

quiet_cd() {
  cd "$@" >/dev/null || return
}

SHELL_FILE_DIRECTORY="$(quiet_cd "${0%/*}/" && pwd -P)"

${SHELL_FILE_DIRECTORY}/homeskel/bin/skel install-server
