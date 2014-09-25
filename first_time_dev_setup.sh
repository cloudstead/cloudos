#!/bin/bash

git submodule init
git submodule update
cd cobbzilla-parent
mvn install
cd ..
