#!/bin/bash

BASE=$(cd $(dirname $0) && pwd)
cd ${BASE}

git submodule init
git submodule update

pushd utils
git submodule init
git submodule update
popd
