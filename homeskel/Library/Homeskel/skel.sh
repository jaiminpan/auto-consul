
CELLAR_NAME="Nebular"

# Force UTF-8 to avoid encoding issues for users with broken locale settings.
if [[ "$(locale charmap 2>/dev/null)" != "UTF-8" ]]
then
  export LC_ALL="en_US.UTF-8"
fi

# Where we store built products; a CELLAR_NAME in HOMESKEL_PREFIX (often /usr/local
# for bottles) unless there's already a CELLAR_NAME in HOMESKEL_REPOSITORY.
if [[ -d "$HOMESKEL_REPOSITORY/${CELLAR_NAME}" ]]
then
  HOMESKEL_CELLAR="$HOMESKEL_REPOSITORY/${CELLAR_NAME}"
else
  HOMESKEL_CELLAR="$HOMESKEL_PREFIX/${CELLAR_NAME}"
fi

case "$*" in
  --prefix)            echo "$HOMESKEL_PREFIX"; exit 0 ;;
  --cellar)            echo "$HOMESKEL_CELLAR"; exit 0 ;;
  --repository|--repo) echo "$HOMESKEL_REPOSITORY"; exit 0 ;;
esac

# A depth of 1 means this command was directly invoked by a user.
# Higher depths mean this command was invoked by another Homeskel command.
export HOMESKEL_COMMAND_DEPTH=$((HOMESKEL_COMMAND_DEPTH + 1))

onwarn() {
  if [[ -t 2 ]] # check whether stderr is a tty.
  then
    echo -ne "\\033[4;31mWarn\\033[0m: " >&2 # highlight Warb with underline and red color
  else
    echo -n "Warn: " >&2
  fi
  if [[ $# -eq 0 ]]
  then
    cat >&2
  else
    echo "$*" >&2
  fi
}

onoe() {
  if [[ -t 2 ]] # check whether stderr is a tty.
  then
    echo -ne "\\033[4;31mError\\033[0m: " >&2 # highlight Error with underline and red color
  else
    echo -n "Error: " >&2
  fi
  if [[ $# -eq 0 ]]
  then
    cat >&2
  else
    echo "$*" >&2
  fi
}

odie() {
  onoe "$@"
  exit 1
}

safe_cd() {
  cd "$@" >/dev/null || odie "Error: failed to cd to $*!"
}

skel() {
  "$HOMESKEL_SKEL_FILE" "$@"
}

git() {
  "$HOMESKEL_LIBRARY/Homeskel/shims/scm/git" "$@"
}

numeric() {
  # Condense the exploded argument into a single return value.
  # shellcheck disable=SC2086,SC2183
  printf "%01d%02d%02d%02d" ${1//./ }
}

HOMESKEL_VERSION="$(git -C "$HOMESKEL_REPOSITORY" describe --tags --dirty --abbrev=7 2>/dev/null)"
HOMESKEL_USER_AGENT_VERSION="$HOMESKEL_VERSION"
if [[ -z "$HOMESKEL_VERSION" ]]
then
  HOMESKEL_VERSION=">=1.7.1 (shallow or no git repository)"
  HOMESKEL_USER_AGENT_VERSION="1.X.Y"
fi

if [[ "$HOMESKEL_PREFIX" = "/" || "$HOMESKEL_PREFIX" = "/usr" ]]
then
  # it may work, but I only see pain this route and don't want to support it
  odie "Cowardly refusing to continue at this prefix: $HOMESKEL_PREFIX"
fi

HOMESKEL_SYSTEM="$(uname -s)"
case "$HOMESKEL_SYSTEM" in
  Darwin) HOMESKEL_MACOS="1" ;;
  Linux)  HOMESKEL_LINUX="1" ;;
esac

if [[ -n "$HOMESKEL_MACOS" ]]
then
  HOMESKEL_PROCESSOR="$(uname -p)"
  HOMESKEL_PRODUCT="Homeskel"
  HOMESKEL_SYSTEM="Macintosh"
  # This is i386 even on x86_64 machines
  [[ "$HOMESKEL_PROCESSOR" = "i386" ]] && HOMESKEL_PROCESSOR="Intel"
  HOMESKEL_MACOS_VERSION="$(/usr/bin/sw_vers -productVersion)"
  HOMESKEL_OS_VERSION="macOS $HOMESKEL_MACOS_VERSION"
  # Don't change this from Mac OS X to match what macOS itself does in Safari on 10.12
  HOMESKEL_OS_USER_AGENT_VERSION="Mac OS X $HOMESKEL_MACOS_VERSION"

  # The system Curl is too old for some modern HTTPS certificates on
  # older macOS versions.
  #
  # Intentionally set this variable by exploding another.
  # shellcheck disable=SC2086,SC2183
  printf -v HOMESKEL_MACOS_VERSION_NUMERIC "%02d%02d%02d" ${HOMESKEL_MACOS_VERSION//./ }
  if [[ "$HOMESKEL_MACOS_VERSION_NUMERIC" -lt "101000" ]]
  then
    HOMESKEL_SYSTEM_CURL_TOO_OLD="1"
    HOMESKEL_FORCE_SKELED_CURL="1"
  fi

  # Announce pre-Mavericks deprecation now
  if [[ "$HOMESKEL_MACOS_VERSION_NUMERIC" -lt "100900" ]]
  then
    printf "WARNING: Your version of macOS (%s) will not be able to run Homeskel when\n" "$HOMESKEL_MACOS_VERSION" >&2
    printf "         version 2.0.0 is released (Q1 2019)!\n" >&2
    if [[ "$HOMESKEL_MACOS_VERSION_NUMERIC" -lt "100700" ]]
    then
      printf "         For 10.4 - 10.6 support see: https://github.com/mistydemeo/tigerskel\n" >&2
    fi
    printf "\n" >&2
  fi

  # The system Git on macOS versions before Sierra is too old for some Homeskel functionality we rely on.
  HOMESKEL_MINIMUM_GIT_VERSION="2.14.3"
  if [[ "$HOMESKEL_MACOS_VERSION_NUMERIC" -lt "101200" ]]
  then
    HOMESKEL_FORCE_SKELED_GIT="1"
  fi

  HOMESKEL_CACHE="${HOMESKEL_CACHE:-${HOME}/Library/Caches/Homeskel}"
  HOMESKEL_LOGS="${HOMESKEL_LOGS:-${HOME}/Library/Logs/Homeskel}"
  HOMESKEL_SYSTEM_TEMP="/private/tmp"
else
  HOMESKEL_PROCESSOR="$(uname -m)"
  HOMESKEL_PRODUCT="${HOMESKEL_SYSTEM}skel"
  [[ -n "$HOMESKEL_LINUX" ]] && HOMESKEL_OS_VERSION="$(lsb_release -sd 2>/dev/null)"
  : "${HOMESKEL_OS_VERSION:=$(uname -r)}"
  HOMESKEL_OS_USER_AGENT_VERSION="$HOMESKEL_OS_VERSION"

  # Ensure the system Curl is a version that supports modern HTTPS certificates.
  HOMESKEL_MINIMUM_CURL_VERSION="7.41.0"
  system_curl_version_output="$($(command -v curl) --version 2>/dev/null)"
  system_curl_name_and_version="${system_curl_version_output%% (*}"
  if [[ $(numeric "${system_curl_name_and_version##* }") -lt $(numeric "$HOMESKEL_MINIMUM_CURL_VERSION") ]]
  then
    HOMESKEL_SYSTEM_CURL_TOO_OLD="1"
    HOMESKEL_FORCE_SKELED_CURL="1"
  fi

  # Ensure the system Git is at or newer than the minimum required version.
  # Git 2.7.4 is the version of git on Ubuntu 16.04 LTS (Xenial Xerus).
  HOMESKEL_MINIMUM_GIT_VERSION="2.7.0"
  system_git_version_output="$($(command -v git) --version 2>/dev/null)"
  if [[ $(numeric "${system_git_version_output##* }") -lt $(numeric "$HOMESKEL_MINIMUM_GIT_VERSION") ]]
  then
    HOMESKEL_FORCE_SKELED_GIT="1"
  fi

  CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
  HOMESKEL_CACHE="${HOMESKEL_CACHE:-${CACHE_HOME}/Homeskel}"
  HOMESKEL_LOGS="${HOMESKEL_LOGS:-${CACHE_HOME}/Homeskel/Logs}"
  HOMESKEL_SYSTEM_TEMP="/tmp"
fi

if [[ -n "$HOMESKEL_MACOS" || -n "$HOMESKEL_FORCE_HOMESKEL_ON_LINUX" ]]
then
  HOMESKEL_BOTTLE_DEFAULT_DOMAIN="https://homeskel.bintray.com"
else
  HOMESKEL_BOTTLE_DEFAULT_DOMAIN="https://linuxskel.bintray.com"
fi

HOMESKEL_TEMP="${HOMESKEL_TEMP:-${HOMESKEL_SYSTEM_TEMP}}"

if [[ -n "$HOMESKEL_FORCE_SKELED_CURL" &&
      -x "$HOMESKEL_PREFIX/opt/curl/bin/curl" ]] &&
         "$HOMESKEL_PREFIX/opt/curl/bin/curl" --version >/dev/null
then
  HOMESKEL_CURL="$HOMESKEL_PREFIX/opt/curl/bin/curl"
elif [[ -n "$HOMESKEL_DEVELOPER" && -x "$HOMESKEL_CURL_PATH" ]]
then
  HOMESKEL_CURL="$HOMESKEL_CURL_PATH"
else
  HOMESKEL_CURL="curl"
fi

if [[ -n "$HOMESKEL_FORCE_SKELED_GIT" &&
      -x "$HOMESKEL_PREFIX/opt/git/bin/git" ]] &&
         "$HOMESKEL_PREFIX/opt/git/bin/git" --version >/dev/null
then
  HOMESKEL_GIT="$HOMESKEL_PREFIX/opt/git/bin/git"
elif [[ -n "$HOMESKEL_DEVELOPER" && -x "$HOMESKEL_GIT_PATH" ]]
then
  HOMESKEL_GIT="$HOMESKEL_GIT_PATH"
else
  HOMESKEL_GIT="git"
fi

HOMESKEL_USER_AGENT="$HOMESKEL_PRODUCT/$HOMESKEL_USER_AGENT_VERSION ($HOMESKEL_SYSTEM; $HOMESKEL_PROCESSOR $HOMESKEL_OS_USER_AGENT_VERSION)"
curl_version_output="$("$HOMESKEL_CURL" --version 2>/dev/null)"
curl_name_and_version="${curl_version_output%% (*}"
HOMESKEL_USER_AGENT_CURL="$HOMESKEL_USER_AGENT ${curl_name_and_version// //}"

# Declared in bin/SKEL
export HOMESKEL_SKEL_FILE
export HOMESKEL_PREFIX
export HOMESKEL_REPOSITORY
export HOMESKEL_LIBRARY
export HOMESKEL_SYSTEM_TEMP
export HOMESKEL_TEMP

# Declared in skel.sh
export HOMESKEL_VERSION
export HOMESKEL_CACHE
export HOMESKEL_LOGS
export HOMESKEL_CELLAR
export HOMESKEL_SYSTEM
export HOMESKEL_CURL
export HOMESKEL_SYSTEM_CURL_TOO_OLD
export HOMESKEL_GIT
export HOMESKEL_MINIMUM_GIT_VERSION
export HOMESKEL_PROCESSOR
export HOMESKEL_PRODUCT
export HOMESKEL_OS_VERSION
export HOMESKEL_MACOS_VERSION
export HOMESKEL_MACOS_VERSION_NUMERIC
export HOMESKEL_USER_AGENT
export HOMESKEL_USER_AGENT_CURL

if [[ -n "$HOMESKEL_MACOS" && -x "/usr/bin/xcode-select" ]]
then
  XCODE_SELECT_PATH=$('/usr/bin/xcode-select' --print-path 2>/dev/null)
  if [[ "$XCODE_SELECT_PATH" = "/" ]]
  then
    odie <<EOS
Your xcode-select path is currently set to '/'.
This causes the 'xcrun' tool to hang, and can render Homeskel unusable.
If you are using Xcode, you should:
  sudo xcode-select -switch /Applications/Xcode.app
Otherwise, you should:
  sudo rm -rf /usr/share/xcode-select
EOS
  fi

  # Don't check xcrun if Xcode and the CLT aren't installed, as that opens
  # a popup window asking the user to install the CLT
  if [[ -n "$XCODE_SELECT_PATH" ]]
  then
    XCRUN_OUTPUT="$(/usr/bin/xcrun clang 2>&1)"
    XCRUN_STATUS="$?"

    if [[ "$XCRUN_STATUS" -ne 0 && "$XCRUN_OUTPUT" = *license* ]]
    then
      odie <<EOS
You have not agreed to the Xcode license. Please resolve this by running:
  sudo xcodebuild -license accept
EOS
    fi
  fi
fi

# Many Pathname operations use getwd when they shouldn't, and then throw
# odd exceptions. Reduce our support burden by showing a user-friendly error.
if [[ ! -d "$(pwd)" ]]
then
  odie "The current working directory doesn't exist, cannot proceed."
fi

if [[ "$1" = -v ]]
then
  # Shift the -v to the end of the parameter list
  shift
  set -- "$@" -v
fi

for arg in "$@"
do
  if [[ $arg = "--help" || $arg = "-h" || $arg = "--usage" || $arg = "-?" ]]
  then
    export HOMESKEL_HELP="1"
    break
  fi
done

HOMESKEL_ARG_COUNT="$#"
HOMESKEL_COMMAND="$1"
shift
case "$HOMESKEL_COMMAND" in
  ls)          HOMESKEL_COMMAND="list" ;;
  homepage)    HOMESKEL_COMMAND="home" ;;
  -S)          HOMESKEL_COMMAND="search" ;;
  up)          HOMESKEL_COMMAND="update" ;;
  ln)          HOMESKEL_COMMAND="link" ;;
  instal)      HOMESKEL_COMMAND="install" ;; # gem does the same
  uninstal)    HOMESKEL_COMMAND="uninstall" ;;
  rm)          HOMESKEL_COMMAND="uninstall" ;;
  remove)      HOMESKEL_COMMAND="uninstall" ;;
  configure)   HOMESKEL_COMMAND="diy" ;;
  abv)         HOMESKEL_COMMAND="info" ;;
  dr)          HOMESKEL_COMMAND="doctor" ;;
  --repo)      HOMESKEL_COMMAND="--repository" ;;
  environment) HOMESKEL_COMMAND="--env" ;;
  --config)    HOMESKEL_COMMAND="config" ;;
  -v)          HOMESKEL_COMMAND="--version" ;;
esac

if [[ "$HOMESKEL_COMMAND" = "cask" ]]
then
  HOMESKEL_CASK_COMMAND="$1"

  case "$HOMESKEL_CASK_COMMAND" in
    instal) HOMESKEL_CASK_COMMAND="install" ;; # gem does the same
  esac
fi

# Set HOMESKEL_DEV_SKEL_RUN for users who have run a development command.
# This makes them behave like HOMESKEL_DEVELOPERs for SKEL update.
if [[ -z "$HOMESKEL_DEVELOPER" ]]
then
  export HOMESKEL_GIT_CONFIG_FILE="$HOMESKEL_REPOSITORY/.git/config"
  HOMESKEL_GIT_CONFIG_DEVELOPERMODE="$(git config --file="$HOMESKEL_GIT_CONFIG_FILE" --get homeskel.devcmdrun 2>/dev/null)"
  if [[ "$HOMESKEL_GIT_CONFIG_DEVELOPERMODE" = "true" ]]
  then
    export HOMESKEL_DEV_SKEL_RUN="1"
  fi

  # Don't allow non-developers to customise Ruby warnings.
  unset HOMESKEL_RUBY_WARNINGS
fi

if [[ -z "$HOMESKEL_RUBY_WARNINGS" ]]
then
  export HOMESKEL_RUBY_WARNINGS="-W0"
fi

if [[ -z "$HOMESKEL_BOTTLE_DOMAIN" ]]
then
  export HOMESKEL_BOTTLE_DOMAIN="$HOMESKEL_BOTTLE_DEFAULT_DOMAIN"
fi

if [[ -f "$HOMESKEL_LIBRARY/Homeskel/cmd/$HOMESKEL_COMMAND.sh" ]]
then
  HOMESKEL_BASH_COMMAND="$HOMESKEL_LIBRARY/Homeskel/cmd/$HOMESKEL_COMMAND.sh"
elif [[ -f "$HOMESKEL_LIBRARY/Homeskel/dev-cmd/$HOMESKEL_COMMAND.sh" ]]
then
  if [[ -z "$HOMESKEL_DEVELOPER" ]]
  then
    git config --file="$HOMESKEL_GIT_CONFIG_FILE" --replace-all homeskel.devcmdrun true 2>/dev/null
    export HOMESKEL_DEV_SKEL_RUN="1"
  fi
  HOMESKEL_BASH_COMMAND="$HOMESKEL_LIBRARY/Homeskel/dev-cmd/$HOMESKEL_COMMAND.sh"
fi

if [[ -f "$HOMESKEL_LIBRARY/Homeskel/cmd/$HOMESKEL_COMMAND.do.sh" ]]
then
  HOMESKEL_DO_COMMAND="$HOMESKEL_LIBRARY/Homeskel/cmd/$HOMESKEL_COMMAND.do.sh"
elif [[ -f "$HOMESKEL_LIBRARY/Homeskel/dev-cmd/$HOMESKEL_COMMAND.do.sh" ]]
then
  HOMESKEL_DO_COMMAND="$HOMESKEL_LIBRARY/Homeskel/dev-cmd/$HOMESKEL_COMMAND.do.sh"
fi

check-run-command-as-root() {
  [[ "$(id -u)" = 0 ]] || return

  # Homeskel Services may need `sudo` for system-wide daemons.
  [[ "$HOMESKEL_COMMAND" = "services" ]] && return

  # It's fine to run this as root as it's not changing anything.
  [[ "$HOMESKEL_COMMAND" = "--prefix" ]] && return

  odie <<EOS
Running Homeskel as root is extremely dangerous and no longer supported.
As Homeskel does not drop privileges on installation you would be giving all
build scripts full access to your system.
EOS
}
check-run-command-as-root

check-prefix-is-not-tmpdir() {
  [[ -z "${HOMESKEL_MACOS}" ]] && return

  if [[ "${HOMESKEL_PREFIX}" = "${HOMESKEL_TEMP}"* ]]
  then
    odie <<EOS
Your HOMESKEL_PREFIX is in the Homeskel temporary directory, which Homeskel
uses to store downloads and builds. You can resolve this by installing Homeskel to
either the standard prefix (/usr/local) or to a non-standard prefix that is not
in the Homeskel temporary directory.
EOS
  fi
}
check-prefix-is-not-tmpdir

if [[ "$HOMESKEL_PREFIX" = "/usr/local" &&
      "$HOMESKEL_PREFIX" != "$HOMESKEL_REPOSITORY" &&
      "$HOMESKEL_CELLAR" = "$HOMESKEL_REPOSITORY/${CELLAR_NAME}" ]]
then
  cat >&2 <<EOS
Warning: your HOMESKEL_PREFIX is set to /usr/local but HOMESKEL_CELLAR is set
to $HOMESKEL_CELLAR. Your current HOMESKEL_CELLAR location will stop
you being able to use all the binary packages (bottles) Homeskel provides. We
recommend you move your HOMESKEL_CELLAR to /usr/local/CELLAR_NAME which will get you
access to all bottles."
EOS
fi

# Don't need shellcheck to follow this `source`.
# shellcheck disable=SC1090
source "$HOMESKEL_LIBRARY/Homeskel/utils/analytics.sh"
setup-analytics

if [[ -n "$HOMESKEL_BASH_COMMAND" ]]
then
  # source rather than executing directly to ensure the entire file is read into
  # memory before it is run. This makes running a Bash script behave more like
  # a Ruby script and avoids hard-to-debug issues if the Bash script is updated
  # at the same time as being run.
  #
  # Don't need shellcheck to follow this `source`.
  # shellcheck disable=SC1090
  source "$HOMESKEL_BASH_COMMAND"
  { "homeskel-$HOMESKEL_COMMAND" "$@"; exit $?; }
elif [[ -n "$HOMESKEL_DO_COMMAND" ]]
then
  source "$HOMESKEL_DO_COMMAND"
  # Unshift command back into argument list (unless argument list was empty).
  [[ "$HOMESKEL_ARG_COUNT" -gt 0 ]] && set -- "$HOMESKEL_COMMAND" "$@"
  { "homeskel-$HOMESKEL_COMMAND" "$@"; exit $?; }
else
  odie "Missing HOMESKEL_BASH_COMMAND $HOMESKEL_BASH_COMMAND $HOMESKEL_COMMAND $@"
fi
