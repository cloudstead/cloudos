#!/bin/bash
#
# Package up code so it can be used during deployment, either as server-side webapps or cloudos app bundles.
#
# Usage:
#   prep-deploy.sh [no-gen-sql] <app-name>
#
# If no-gen-sql is the first argument, then no SQL schema generation will occur.
#
# Examples:
#   prep-deploy.sh cloudos-server     # create the cloudos-server.tar.gz tarball 
#   prep-deploy.sh cloudos-appstore   # create the cloudos-appstore.tar.gz tarball 
#   prep-deploy.sh cloudos-apps       # create the various app tarballs
#
# Care must be taken when editing this file -- the "prep.sh" script (which calls prep-deploy.sh on each 
# deployable component) expects ALL output to stdout to be names of artifacts (file paths) that should be 
# rsync'd to the remote host. If you need to "echo" something, please echo to stderr (echo 1>&2 "log something") 
#

function die () {
  echo 1>&2 "${1}"
  exit 1
}

NO_GEN_SQL=""
if [ "${1}" = "no-gen-sql" ] ; then
  NO_GEN_SQL="${1}"
  shift
fi

APP=${1}
if [ -z ${APP} ] ; then
  die "Usage: $0 <app>"
fi

BASE=$(cd $(dirname $0) && pwd)
APP_DIR=$(find ${BASE} -maxdepth 3 -type d -name ${APP} | grep -v '.git/' | grep -v '/apps/' | grep -v '/target/')
if [ -z ${APP_DIR} ] ; then
  die "App does not exist: ${APP}"  # should never happen
fi

cd ${APP_DIR}
DEPLOY=target/${APP}

# If this has a src/main/resources/spring.xml file, treat it like a web app
IS_SERVER=0
if [ -f ${APP_DIR}/src/main/resources/spring.xml ] ; then
  IS_SERVER=1
fi

if [ ${IS_SERVER} -eq 1 ] ; then
    if [[ ! -d target || $(find target -type f -name "${APP}*.jar" | wc -l | tr -d ' ') -eq 0 ]] ; then
      echo 1>&2 "${APP} jar not found, building it"
      mvn -DskipTests=true clean package 1>&2
    fi

    if [ $(find target -type f -name "${APP}*.jar" | wc -l | tr -d ' ') -eq 0 ] ; then
      echo 1>&2 "Error building ${APP}."
      exit 1
    fi

    mkdir -p ${DEPLOY}/target
    mkdir -p ${DEPLOY}/logs

    # Old-style static assets: directly in resources dir
    if [ -d src/main/resources/static ] ; then
        mkdir -p ${DEPLOY}/site
        cp -R src/main/resources/static/* ${DEPLOY}/site

    # New-style static assets: generated by lineman and put under target dir
    elif [ -d target/classes/static ] ; then
        mkdir -p ${DEPLOY}/site
        cp -R target/classes/static/* ${DEPLOY}/site
    fi

    if [[ -x gen-sql.sh ]] && [[ -z ${NO_GEN_SQL} ]] ; then
      GEN_SQL_LOG=$(mktemp /tmp/gen-sql.XXXXXXX)
      ./gen-sql.sh 2>&1 > ${GEN_SQL_LOG}
      if [ $? -ne 0 ] ; then
          echo 1>&2 "Error running gen-sql.sh: check ${GEN_SQL_LOG}"
          exit 1
      fi
      rm -f ${GEN_SQL_LOG}
    fi

    cp target/${APP}-*.jar ${DEPLOY}/target
fi

# Delegate to app-specific stuff (or for non-servers, do everything here)
if [ -f ${APP_DIR}/prep-deploy.sh ] ; then
  ${APP_DIR}/prep-deploy.sh ${DEPLOY}

else
  echo 1>&2 "No app found in ${APP_DIR}"
  exit 1
fi

if [ ${IS_SERVER} -eq 1 ] ; then
    # Non-servers do their own packaging
    cd target && tar czf ${APP}.tar.gz ${APP}
    echo ${APP_DIR}/target/${APP}.tar.gz
fi
