#!/usr/bin/env bash
#
# This script packages a Diamond release as a RHEL6/CentOS6 RPM.
#

### CONFIGURATION BEGINS ###

# Normally you do not need to change this variable
DIAMOND_GIT_REPO="https://github.com/BrightcoveOS/Diamond.git"

### CONFIGURATION ENDS ###

function print_usage() {
    myself=`basename $0`
    echo "Usage: $myself <diamond-release-version-or-git-commit>"
    echo
    echo "Examples:"
    echo "  \$ $myself v3.4   # release tag"
    echo "  \$ $myself 05942d83fd1a86b5dc16a5610dcaba7ca4463e3a   # git commit"
}

if [ $# -ne 1 ]; then
    print_usage
    exit 1
fi

DIAMOND_VERSION="$1"

echo "Building an RPM for Diamond release version $DIAMOND_VERSION..."

# Prepare environment
OLD_PWD=`pwd`
BUILD_DIR=`mktemp -d /tmp/diamond-build.XXXXXXXXXX`
cd $BUILD_DIR

cleanup_and_exit() {
  local exitCode=$1
  rm -rf $BUILD_DIR
  cd $OLD_PWD
  exit $exitCode
}

# Download
git clone $DIAMOND_GIT_REPO || cleanup_and_exit $?
cd Diamond || cleanup_and_exit $?
git checkout ${DIAMOND_VERSION} || cleanup_and_exit $?

# Build the RPM
#
# Normally we'd prefer to use `make rpm` combined with a custom `localversion` file.  Unfortunately Diamond uses
# `localversion` as a suffix for the RPM version string, and does not expose a way to customize the RPM release string.
# For this reason we manually perform the equivalent of `make rpm`;  this way we do not need to modify the Diamond
# sources.  We introduce the risk though that the Diamond project may modify the functionality of `make rpm` without
# us being aware of that change.
RELEASE="1.miguno"
make sdist || cleanup_and_exit $?
# See https://docs.python.org/2/distutils/builtdist.html
./setup.py bdist_rpm --release=$RELEASE || cleanup_and_exit $?

# Rename the RPM to fit our style
ORIG_RPM=`find dist/ -name "diamond-*.noarch.rpm" | head -n 1`
ORIG_RPM_FILENAME=`basename $ORIG_RPM`
NEW_RPM_FILENAME=`echo $ORIG_RPM_FILENAME | sed -r 's/\.noarch\./\.el6\.x86_64\./'`
cp $ORIG_RPM $OLD_PWD/$NEW_RPM_FILENAME

echo "You can verify the proper creation of the RPM file with:"
echo "  \$ rpm -qpi diamond-*.rpm    # show package info"
echo "  \$ rpm -qpR diamond-*.rpm    # show package dependencies"
echo "  \$ rpm -qpl diamond-*.rpm    # show contents of package"

# Clean up
cleanup_and_exit 0
