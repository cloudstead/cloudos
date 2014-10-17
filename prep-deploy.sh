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

    APP_NAME="$(grep artifactId pom.xml | head -2 | grep ${APP} | tr '<>' '  ' | awk '{print $2}')"
    DEPLOY=target/${APP_NAME}
    JAR_MATCH="${APP_NAME}*.jar"

    if [[ ! -d target || $(find target -type f -name "${JAR_MATCH}" | wc -l | tr -d ' ') -eq 0 ]] ; then
      echo 1>&2 "${APP} jar not found, building it"
      mvn -DskipTests=true clean package 1>&2
    fi

    NUM_JARS=$(find target -type f -name "${JAR_MATCH}" | grep -v '/target/' | wc -l | tr -d ' ')
    if [ ${NUM_JARS} -gt 1 ] ; then
      die "Multiple jars found: $(find target -type f -name ${JAR_MATCH})"
    fi
    if [ ${NUM_JARS} -eq 0 ] ; then
      echo 1>&2 "Error building ${APP}."
      exit 1
    fi

    mkdir -p ${DEPLOY}/target
    mkdir -p ${DEPLOY}/logs

    # New-style static assets: generated by lineman and put under target dir
    if [ -d target/classes/static ] ; then
        mkdir -p ${DEPLOY}/site
        cp -R target/classes/static/* ${DEPLOY}/site

    # Old-style static assets: directly in resources dir
    elif [ -d src/main/resources/static ] ; then
        mkdir -p ${DEPLOY}/site
        cp -R src/main/resources/static/* ${DEPLOY}/site

    fi

    if [[ -x gen-sql.sh ]] && [[ -z ${NO_GEN_SQL} ]] ; then
      GEN_SQL_LOG=$(mktemp /tmp/gen-sql.XXXXXXX)
      ./gen-sql.sh silent 2>&1 > ${GEN_SQL_LOG}
      if [ $? -ne 0 ] ; then
          echo 1>&2 "Error running gen-sql.sh: check ${GEN_SQL_LOG}"
          exit 1
      fi
      rm -f ${GEN_SQL_LOG}
    fi

    cp target/${JAR_MATCH} ${DEPLOY}/target
fi

# Delegate to app-specific stuff
if [ -f ${APP_DIR}/prep-deploy.sh ] ; then
  ${APP_DIR}/prep-deploy.sh ${DEPLOY}

else
  echo 1>&2 "No app found in ${APP_DIR}"
  exit 1
fi

if [ ${IS_SERVER} -eq 1 ] ; then
    # Non-servers do their own packaging
    cd target && tar czf ${APP_NAME}.tar.gz ${APP_NAME}
    echo ${APP_DIR}/target/${APP_NAME}.tar.gz
fi
