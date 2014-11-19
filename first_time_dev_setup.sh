#!/bin/bash

BASE=$(cd $(dirname $0) && pwd)
cd ${BASE}

cd $(cd $(dirname $0) && pwd)
git submodule init
git submodule update

pushd utils
git submodule init
git submodule update
popd

pushd utils/cobbzilla-parent
mvn install
popd
