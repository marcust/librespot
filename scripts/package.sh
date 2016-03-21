#!/bin/sh

set -ue

SCRIPT_DIR=$(pwd)/$(dirname $0)
DEBIAN_FILES=${SCRIPT_DIR}/../debian

DATESTAMP=$(date +%Y%m%d)
VERSION=0.1.0
HASH=$(curl -s "https://api.github.com/repos/plietar/librespot/branches/master" | jq -r '.commit.sha' | cut -c-7)
PACKAGE_VERSION=${VERSION}~git${DATESTAMP}.${HASH}

TARGET_TAR=/tmp/librespot_$PACKAGE_VERSION.orig.tar.gz
TARGET_DIR=/tmp/librespot-${PACKAGE_VERSION};

if [ -f ${TARGET_TAR} ]; then
    sudo rm -fv ${TARGET_TAR};
fi

if [ -e ${TARGET_DIR} ]; then
    sudo rm -rfv ${TARGET_DIR};
fi

wget -O ${TARGET_TAR} https://github.com/plietar/librespot/archive/$HASH.tar.gz

BASEDIR=$(tar tzf ${TARGET_TAR} | head -n 1)

cd /tmp

tar xvzf ${TARGET_TAR};

mv ${BASEDIR} ${TARGET_DIR}

cd ${TARGET_DIR}

cp -r ${DEBIAN_FILES} ${TARGET_DIR}

dch -v "${PACKAGE_VERSION}-1" "New git revision $HASH"

TOOL_PACKAGES="dpkg-dev curl sudo devscripts aptitude equivs fakeroot"

ARCH=$(dpkg --print-architecture)

EXTRA_CMD="/bin/true"
if [ ${ARCH} = "armhf" ]; then
    BASE_IMAGE="marcust/jessie-armhf-rust:stable"
fi
if [ ${ARCH} = "amd64" -o ${ARCH} = "i386" ]; then
    BASE_IMAGE="ubuntu:15.10"
    EXTRA_CMD="curl -sSf https://static.rust-lang.org/rustup.sh | sh"
fi

docker run  -v /tmp:/tmp -w ${TARGET_DIR} $BASE_IMAGE /bin/bash -c "apt-get update &&\
                                                                     apt-get -y upgrade &&\
                                                                     apt-get install -y ${TOOL_PACKAGES} &&\
                                                                     $EXTRA_CMD  &&\
                                                                     mk-build-deps -i -t \"apt-get -y \" &&\
  	                       		        	             dpkg-checkbuilddeps &&\
                                                                     dpkg-buildpackage -us -uc -rfakeroot"

