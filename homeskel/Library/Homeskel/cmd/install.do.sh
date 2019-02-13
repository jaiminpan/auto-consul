
homeskel-install() {

  TAR_NAME="consul_1.4.1_linux_amd64.zip"

  PROJ_PREFIX="${HOMESKEL_PREFIX%/*}"

  unzip ${PROJ_PREFIX}/tar/${TAR_NAME} -d "${PROJ_PREFIX}/bin"
}
