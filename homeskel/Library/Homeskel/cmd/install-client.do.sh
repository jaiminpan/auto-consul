
homeskel-install-client() {

  TAR_NAME="consul_1.4.1_linux_amd64.zip"

  PROJ_PREFIX="${HOMESKEL_PREFIX%/*}"

  if [[ -f "${PROJ_PREFIX}/bin/consul" ]]
  then
    odie "Executable Exists ${PROJ_PREFIX}/bin/consul"
  fi

  unzip ${PROJ_PREFIX}/tar/${TAR_NAME} -d "${PROJ_PREFIX}/bin"

  mkdir -p ${PROJ_PREFIX}/data
}
