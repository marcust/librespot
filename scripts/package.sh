#!/bin/sh

set -ue

SCRIPT_DIR=$(dirname $0)
DEBIAN_FILES=$(pwd)/${SCRIPT_DIR}/../debian

DATESTAMP=$(date +%Y%m%d%H%M%S)
VERSION=0.1.0
HASH=$(curl -s "https://api.github.com/repos/marcust/librespot/branches/logging" | jq -r '.commit.sha' | cut -c-7)
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

TOOL_PACKAGES="dpkg-dev curl sudo devscripts aptitude equivs fakeroot gcc file ca-certificates"

ARCH=$(dpkg --print-architecture)

EXTRA_CMD="/bin/true"
if [ ${ARCH} = "arm64" ]; then
    BASE_IMAGES="marcust/jessie-arm64-rust:stable marcust/xenial-arm64-rust:stable"
fi
if [ ${ARCH} = "armhf" ]; then
    BASE_IMAGES="marcust/jessie-armhf-rust:stable marcust/wily-armhf-rust:stable marcust/trusty-armhf-rust:stable marcust/xenial-armhf-rust:stable"
fi
if [ ${ARCH} = "amd64" ]; then
    BASE_IMAGES="ubuntu:wily ubuntu:trusty ubuntu:xenial ubuntu:yakkety debian:jessie debian:wheezy"
    EXTRA_CMD="curl -sSf https://static.rust-lang.org/rustup.sh | sh -s -- --channel=stable"
fi
if [ ${ARCH} = "i386" ]; then
    BASE_IMAGES="ioft/i386-ubuntu:trusty ioft/i386-ubuntu:xenial ioft/i386-ubuntu:wily resin/i386-debian:jessie resin/i386-debian:wheezy"
    EXTRA_CMD="curl -sSf https://static.rust-lang.org/rustup.sh | sh -s -- --channel=stable"
fi

for BASE_IMAGE in ${BASE_IMAGES}; do

    docker run  -v /tmp:/tmp -w ${TARGET_DIR} $BASE_IMAGE /bin/bash -c "apt-get update &&\
                                                                     apt-get -y upgrade &&\
                                                                     apt-get install -y ${TOOL_PACKAGES} &&\
                                                                     $EXTRA_CMD  &&\
                                                                     mk-build-deps -r -i -t \"apt-get -y \" &&\
  	                       		        	             dpkg-checkbuilddeps &&\
                                                                     dpkg-buildpackage -us -uc -rfakeroot &&\
                                                                     cargo clean &&\
                                                                     rm -rf target .crates.toml"

    DIST_NAME=$(echo $BASE_IMAGE | cut -d':' -f 2)
    if [ ${DIST_NAME} = "stable" ]; then
	DIST_NAME=$(echo $BASE_IMAGE | cut -d'-' -f 1 | cut -d'/' -f 2)
    fi
    

    FILENAME=$(basename $(ls /tmp/librespot_${PACKAGE_VERSION}*.deb))
    /home/marcus/bin/dropbox_uploader.sh upload /tmp/${FILENAME} /Public/librespot/${DIST_NAME}/${ARCH}/${FILENAME}

done;

