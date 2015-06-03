#!/bin/bash
#
# Don't run this script directly. It is called by the first_time_dev_setup.sh script
#

BASE=$(cd $(dirname $0) && pwd)
cd ${BASE}

git submodule init
git submodule update

pushd utils
git submodule init
git submodule update
popd
