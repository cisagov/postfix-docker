#!/usr/bin/env bash

# Usage:
#   bump_version.sh (show|major|minor|patch|finalize)
#   bump_version.sh (build|prerelease) [token]
# Notes:
#   - If you specify a token it will only be used if the current version is
#     tokenless or if the provided token matches the token used in the current
#     version.

set -o nounset
set -o errexit
set -o pipefail

VERSION_FILE=src/version.txt
README_FILE=README.md

function usage {
  cat << HELP
Usage:
  ${0##*/} (show|major|minor|patch|finalize)
  ${0##*/} (build|prerelease) [token]

Notes:
  - If you specify a token it will only be used if the current version is
    tokenless or if the provided token matches the token used in the current
    version.
HELP
  exit 1
}

function update_version {
  # Comment out periods so they are interpreted as periods and don't
  # just match any character
  old_version_regex=${1//\./\\\.}

  echo Changing version from "$1" to "$2"
  tmp_file=/tmp/version.$$
  sed "s/$old_version_regex/$2/" $VERSION_FILE > $tmp_file
  mv $tmp_file $VERSION_FILE
  sed "s/$old_version_regex/$2/" $README_FILE > $tmp_file
  mv $tmp_file $README_FILE
  git add $VERSION_FILE $README_FILE
  git commit --message "$3"
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  usage
else
  old_version=$(sed -n "s/^__version__ = \"\(.*\)\"$/\1/p" $VERSION_FILE)
  case $1 in
    major | minor | patch)
      if [ $# -ne 1 ]; then
        usage
      fi
      new_version=$(python -c "import semver; print(semver.bump_$1('$old_version'))")
      update_version "$old_version" "$new_version" "Bump version from $old_version to $new_version"
      ;;
    build | prerelease)
      if [ $# -eq 2 ]; then
        new_version=$(python -c "import semver; print(semver.bump_$1('$old_version', token='$2'))")
      else
        new_version=$(python -c "import semver; print(semver.bump_$1('$old_version'))")
      fi
      update_version "$old_version" "$new_version" "Bump version from $old_version to $new_version"
      ;;
    finalize)
      if [ $# -ne 1 ]; then
        usage
      fi
      new_version=$(python -c "import semver; print(semver.finalize_version('$old_version'))")
      update_version "$old_version" "$new_version" "Finalize version from $old_version to $new_version"
      ;;
    show)
      echo "$old_version"
      ;;
    *)
      usage
      ;;
  esac
fi
