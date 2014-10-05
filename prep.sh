#!/bin/bash
#
# Build deployable tarballs and rsync them to a remote host
#
# Usage:
#   prep.sh [no-gen-sql] [user@remote-host:]/some/path [all|package1 package2 ...]
#
# If no-gen-sql is the first argument, then no SQL schema generation will occur.
#
# A package must have a prep-deploy.sh script in its root.
# A package's prep-deploy.sh script MUST
# - upon success, the only output is a list of absolute paths representing packages to sync. one per line.
# - upon failure, the exit code is non-zero (this prep.sh script will not sync anything for that package)
#
# If no packages are provided, or the special package name 'all' is provided, then any subdirectory
# within a depth of 3 that has a prep-deploy.sh script is presumed to be a deployable package, and is
# thus prepped (packaged and rsync'd).
#
# Examples:
#   # build cloudos-server tarball and rsync to remote host 
#   prep.sh ubuntu@192.168.1.1:/usr/local/apache2/htdocs/ cloudos-server    
#
#   # build cloudos-server tarball and all app tarballs, and rsync to remote host 
#   prep.sh ubuntu@192.168.1.1:/usr/local/apache2/htdocs/ cloudos-server cloudos-apps
#
#   # build all tarballs and rsync to remote host
#   prep.sh ubuntu@192.168.1.1:/usr/local/apache2/htdocs/
#

function die () {
  echo "${1}" && exit 1
}

BASE=$(cd $(dirname $0) && pwd)
cd ${BASE}

NO_GEN_SQL=""
if [ "${1}" = "no-gen-sql" ] ; then
  NO_GEN_SQL="${1}"
  shift
fi

TARGET="${1}"
if [ -z "${TARGET}" ] ; then
  echo "No target given. Usage: $0 [no-gen-sql] [user@remote-host:]/some/path [all|package1 package2 ...]"
  exit 1
fi

shift
packages="$@"
if [[ -z "${packages}" || "${packages}" = "all" ]] ; then
  packages=$(find ${BASE} -maxdepth 4 -type f -name "prep-deploy.sh" -exec dirname {} \; | xargs -n 1 basename)
fi

for package in ${packages} ; do
  if [[ ${package} = "." || ${package} = $(basename $(pwd)) || ${package} = "cloudos" ]] ; then
    continue # do not recurse :)
  fi
  artifacts=$(bash ${BASE}/prep-deploy.sh ${NO_GEN_SQL} ${package})
  if [ $? -ne 0 ] ; then
    die "Error preparing package: ${package}"
  fi
  if [ -z "${artifacts}" ] ; then
    die "package produced no artifacts: ${package}"
  else
    rsync -avc --progress ${artifacts} ${TARGET} || die "Error copying to ${TARGET}"
  fi
done
