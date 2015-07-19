#!/bin/bash
#
# Package up code so it can be used during deployment, either as server-side webapps or cloudos app bundles.
#
# Usage:
#   prep-deploy.sh [gen-sql] <artifact-type>
#
# If gen-sql is the first argument, then SQL schema generation will occur during the deployment.
#
# Examples:
#   prep-deploy.sh cloudos-server     # create the cloudos-server.tar.gz tarball 
#   prep-deploy.sh cloudos-apps       # create the various app tarballs
#
# Care must be taken when editing this file -- the "prep.sh" script (which calls prep-deploy.sh on each 
# deployable component) expects ALL output to stdout prefixed with "ARTIFACT: " to be names of artifacts
# (file paths) that should be copied to the destination (host or dir). If you need to "echo" something,
# please echo to stderr (echo 1>&2 "log something"), or do not
#
# The way that a particular artifact-type builds its artifacts can be customized by adding a prep-deploy.env
# file in the same directory as the local prep-deploy.sh script.
#
# If prep-deploy.env is present, it may define the following environment variables:
#
#   PD_SKIP_LOCAL_SITE    -- if defined, no local site files will be copied to the server artifact tarball.
#                            if not defined, local site files will be copied
#                            if the artifact-type is not a server, then this setting has no effect
#
#   PD_CUSTOM_ARTIFACTS   -- if defined, a server tarball artifact will not be produced. Instead the local
#                              prep-deploy.sh script is expected to generate and declare the artifacts
#                            if not defined, then the normal server tarball artifact will be produced.
#                            if the artifact-type is not a server, then this setting has no effect
#

function die () {
  echo 1>&2 "${1}"
  exit 1
}

GEN_SQL=""
if [ "${1}" = "gen-sql" ] ; then
  GEN_SQL="${1}"
  shift
fi

ARTIFACT=${1}
if [ -z ${ARTIFACT} ] ; then
  die "Usage: $0 <artifact-type>"
fi

BASE=$(cd $(dirname $0) && pwd)
ARTIFACT_DIR=$(find ${BASE}/ -maxdepth 3 -type d -name ${ARTIFACT} | grep -v '.git/' | grep -v '/apps/' | grep -v '/target/')
if [ -z ${ARTIFACT_DIR} ] ; then
  die "Artifact dir not found for ${ARTIFACT}"  # should never happen
fi

cd ${ARTIFACT_DIR}
DEPLOY=target/${ARTIFACT}

# If this has a src/main/resources/spring.xml file, treat it like a web app
IS_SERVER=0
if [ -f ${ARTIFACT_DIR}/src/main/resources/spring.xml ] ; then
  IS_SERVER=1
fi

if [ ${IS_SERVER} -eq 1 ] ; then

    ARTIFACT_NAME="$(grep artifactId pom.xml | head -2 | grep ${ARTIFACT} | tr '<>' '  ' | awk '{print $2}')"
    DEPLOY=target/${ARTIFACT_NAME}
    JAR_MATCH="${ARTIFACT_NAME}*.jar"

    if [[ ! -d target || $(find target -maxdepth 1 -type f -name "${JAR_MATCH}" | wc -l | tr -d ' ') -eq 0 ]] ; then
      echo 1>&2 "${ARTIFACT} jar not found, building it"
      mvn -DskipTests=true clean package 1>&2
    fi

    NUM_JARS=$(find target -maxdepth 1 -type f -name "${JAR_MATCH}" | grep -v '/target/' | wc -l | tr -d ' ')
    if [ ${NUM_JARS} -gt 1 ] ; then
      die "Multiple jars found: $(find target -type f -name ${JAR_MATCH})"
    fi
    if [ ${NUM_JARS} -eq 0 ] ; then
      echo 1>&2 "Error building ${ARTIFACT}."
      exit 1
    fi

    mkdir -p ${DEPLOY}/target
    mkdir -p ${DEPLOY}/logs

    # If there is a prep-deploy.env file, source it
    # See top of this script for env vars that it can contain
    if [ -f prep-deploy.env ] ; then
      . prep-deploy.env
    fi

    # New-style static assets: generated by lineman
    if [ ! -z "${PD_SKIP_LOCAL_SITE}" ] ; then
        echo 1>&2 "Skipping 'site' creation"

    else
        if [ -d csapp/dist ] ; then
            mkdir -p ${DEPLOY}/site
            cp -R csapp/dist/* ${DEPLOY}/site

        # Old-style static assets: directly in resources dir
        elif [ -d src/main/resources/static ] ; then
            mkdir -p ${DEPLOY}/site
            cp -R src/main/resources/static/* ${DEPLOY}/site
        fi

        if [ -d target/api-examples ] ; then
          cp -R target/api-examples ${DEPLOY}/site/
        fi
        if [ -d target/miredot ] ; then
          cp -R target/miredot ${DEPLOY}/site/api-docs
        fi
    fi

    if [[ -x gen-sql.sh && ! -z "${GEN_SQL}" ]] ; then
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
if [ -f ${ARTIFACT_DIR}/prep-deploy.sh ] ; then
  ${ARTIFACT_DIR}/prep-deploy.sh ${DEPLOY}

else
  echo 1>&2 "No deployable artifacts found in ${ARTIFACT_DIR}"
  exit 1
fi

# Non-servers do their own packaging
if [ ${IS_SERVER} -eq 1 ] ; then
    if [ -z ${PD_CUSTOM_ARTIFACTS} ] ; then
        ARTIFACT_ARCHIVE="${ARTIFACT_NAME}.tar.gz"
        cd target && tar czf ${ARTIFACT_ARCHIVE} ${ARTIFACT_NAME}
        echo "ARTIFACT: ${ARTIFACT_DIR}/target/${ARTIFACT_ARCHIVE}"
    fi
fi
