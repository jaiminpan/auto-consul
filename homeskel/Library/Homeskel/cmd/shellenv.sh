#:  * `shellenv`:
#:    Prints export statements - run them in a shell and this installation of
#:    Homebrew will be included into your PATH, MANPATH, and INFOPATH.
#:
#:    HOMESKEL_PREFIX, HOMESKEL_CELLAR and HOMESKEL_REPOSITORY are also exported
#:    to save multiple queries of those variables.
#:
#:    Consider adding evaluating the output in your dotfiles (e.g. `~/.profile`)
#:    with `eval $(brew shellenv)`

homeskel-shellenv() {
  echo "export HOMESKEL_PREFIX=\"$HOMESKEL_PREFIX\""
  echo "export HOMESKEL_CELLAR=\"$HOMESKEL_CELLAR\""
  echo "export HOMESKEL_REPOSITORY=\"$HOMESKEL_REPOSITORY\""
  echo "export PATH=\"$HOMESKEL_PREFIX/bin:$HOMESKEL_PREFIX/sbin:\$PATH\""
  echo "export MANPATH=\"$HOMESKEL_PREFIX/share/man:\$MANPATH\""
  echo "export INFOPATH=\"$HOMESKEL_PREFIX/share/info:\$INFOPATH\""
}
