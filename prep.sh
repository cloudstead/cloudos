#!/bin/bash
#
# Build deployable artifacts and rsync them to a remote host
#
# Usage:
#   prep.sh [gen-sql] [all|artifact-type1 artifact-type2 ...] [user@remote-host:]/some/path
#   prep.sh list      # lists all available artifact types
#
# If gen-sql is the first argument, then SQL schema generation will occur during deployment.
#
# The artifact-type names refer to directory names within the source tree. Each of these directories
# contians a prep-deploy.sh script, which must exist for prep.sh to recognize it as an artifact-type
#
# A package's prep-deploy.sh script MUST conform to the following standards:
# - upon success, its stdout must include at least one line in this form: "ARTIFACT: /absolute/path/to/artifact" (these will be the files to sync)
# - upon failure, its exit code must be non-zero (this script will not sync anything for that package)
#
# If no packages are provided, or the special package name 'all' is provided, then any subdirectory
# within a depth of 3 that has a prep-deploy.sh script is presumed to contain deployable artifacts, and is
# thus prepped (packaged and rsync'd).
#
# Examples:
#   REMOTE_DEST="ubuntu@192.168.1.1:/usr/local/apache2/htdocs/"
#
#   # build cloudos-server tarball and rsync to remote host 
#   prep.sh cloudos-server ${REMOTE_DEST}
#
#   # build cloudos-server tarball and all app tarballs, and rsync to remote host 
#   prep.sh cloudos-server cloudos-apps ${REMOTE_DEST}
#
#   # build all tarballs and rsync to remote host
#   prep.sh ${REMOTE_DEST}
#

BASE=$(cd $(dirname $0) && pwd)
cd ${BASE}

function die () {
  echo "${1}" && exit 1
}

function all_artifact_types {
  # everything with a prep-deploy, but not the bare name 'cloudos' which is a container directory for everything else
  find ${1:-${BASE}}/ -maxdepth ${2:-4} -type f -name "prep-deploy.sh" -exec dirname {} \; | xargs -n 1 basename | egrep -v "^cloudos$"
}

if [[ $# -eq 1 && "${1}" = "list" ]] ; then
  echo "Available artifact types:"
  echo ""
  all_artifact_types
  echo ""
  exit 0
fi

GEN_SQL=""
if [ "${1}" = "gen-sql" ] ; then
  GEN_SQL="${1}"
  shift
fi

# Last argument is the deploy target
TARGET="$(echo ${@} | awk 'NF>1{print $NF}')" # grab the last word

# Artifact types are everything BUT the last word, remove it
artifact_types="$(echo ${@} | sed -e 's,[-A-Za-z0-9@:./]*$,,')" # remove last "word" from list, which could be user@example.com:/path

# Remove leading/trailing whitespace for comparing against special value 'all'
single_type=$(echo ${artifact_types} | tr -d ' ')

if [[ -z "${single_type}" || "${single_type}" = "all" ]] ; then
  artifact_types=$(all_artifact_types)
fi

if [ -z "${TARGET}" ] ; then
  echo "No target given. prep.sh [gen-sql] [user@remote-host:]/some/path [all|list|artifact-type1 artifact-type2 ...]"
  exit 1
fi

# Split artifact_types into "servers" and "apps" so we can do servers first (they may generate SQL files/artifacts for inclusion into apps)
servers=""
apps=""
for artifact_type in ${artifact_types} ; do
  if [ $(echo -n ${artifact_type} | grep -- "-apps" | wc -l | tr -d ' ') -gt 0 ] ; then
    apps="${apps} ${artifact_type}"
  else
    servers="${servers} ${artifact_type}"
  fi
done

for artifact_type in ${servers} ; do
  if [[ ${artifact_type} = "." || ${artifact_type} = $(basename $(pwd)) || ${artifact_type} = "cloudos" ]] ; then
    continue # do not recurse :)
  fi
  artifacts=$(bash ${BASE}/prep-deploy.sh ${GEN_SQL} ${artifact_type} | egrep "^ARTIFACT: " | awk '{print $2}')
  if [ $? -ne 0 ] ; then
    die "Error preparing artifact_type: ${artifact_type}"
  fi
  if [ -z "${artifacts}" ] ; then
    die "artifact_type produced no artifacts: ${artifact_type}"
  else
    rsync -avc --progress ${artifacts} ${TARGET} || die "Error copying ${artifacts} to ${TARGET}"
  fi
done

for artifact_type in ${apps} ; do
  if [[ ${artifact_type} = "." || ${artifact_type} = $(basename $(pwd)) || ${artifact_type} = "cloudos" ]] ; then
    continue # do not recurse :)
  fi
  artifacts=$(bash ${BASE}/prep-deploy.sh ${GEN_SQL} ${artifact_type} | egrep "^ARTIFACT: " | awk '{print $2}')
  if [ $? -ne 0 ] ; then
    die "Error preparing artifact_type: ${artifact_type}"
  fi
  if [ -z "${artifacts}" ] ; then
    die "artifact_type produced no artifacts: ${artifact_type}"
  else
    rsync -avc --progress ${artifacts} ${TARGET} || die "Error copying to ${TARGET}"
  fi
done
