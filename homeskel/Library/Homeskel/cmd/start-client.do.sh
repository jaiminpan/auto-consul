
homeskel-start-client() {

  if [[ -f "${PROJ_CMD_PATH}" ]]
  then
    CMD_FULL_PATH="${PROJ_CMD_PATH}"
  else
    CMD_FULL_PATH="$PROJ_PREFIX/bin/${PROJ_CMD_PATH}"
  fi

  if [[ -d "${PROJ_CONFIG_DIRECTORY}" ]]
  then
    CONFIG_DIR_FULL_PATH="${PROJ_CONFIG_DIRECTORY}"
  else
    CONFIG_DIR_FULL_PATH="$PROJ_PREFIX/${PROJ_CONFIG_DIRECTORY}"
  fi

  if [[ -f "${PROJ_LOG_FILE}" ]]
  then
    LOG_FILE_FULL_PATH="${PROJ_LOG_FILE}"
  else
    LOG_FILE_FULL_PATH="$PROJ_PREFIX/${PROJ_LOG_FILE}"
  fi

  if ! [[ -f "${CMD_FULL_PATH}" ]]
  then
    odie "Command $CMD_FULL_PATH not exists"
  fi

  if ! [[ -d "${CONFIG_DIR_FULL_PATH}" ]]
  then
    odie "Directory $CONFIG_DIR_FULL_PATH not exists"
  fi

  if [[ -f "${LOG_FILE_FULL_PATH}" ]]
  then
    onwarn "Log file $LOG_FILE_FULL_PATH exists"
  fi

  if [[ -n "$PROJ_DAEMON_RUNNABLE" ]]
  then
    echo "Daemon run"
    nohup ${CMD_FULL_PATH} agent -config-dir=${CONFIG_DIR_FULL_PATH} 2>&1 > ${LOG_FILE_FULL_PATH} &
  else
    ${CMD_FULL_PATH} agent -config-dir=${CONFIG_DIR_FULL_PATH}
  fi

}
