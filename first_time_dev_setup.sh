#!/bin/bash

BASE=$(cd $(dirname $0) && pwd)
cd ${BASE}

./first_time_git_setup.sh

pushd utils/cobbzilla-parent
mvn install
popd
