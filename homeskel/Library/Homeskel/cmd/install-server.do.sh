
homeskel-install-server() {

  if ! [[ -n "$HOMESKEL_LINUX" ]]
  then
    odie "Only Support Linux"
  fi
}
