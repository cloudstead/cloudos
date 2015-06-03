#!/bin/bash
#
# Run this script once after cloning the main repository.
# It populates all it submodules and installs the cobbzilla-parent module.
#
# After this script has successfully completed, you will not need to run it again unless you delete the entire repository and start over.
#

BASE=$(cd $(dirname $0) && pwd)
cd ${BASE}

./first_time_git_setup.sh

pushd utils/cobbzilla-parent
mvn install
popd
