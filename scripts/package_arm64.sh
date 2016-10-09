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

ARCH=$(dpkg --print-architecture)

cd ${TARGET_DIR}

dpkg-buildpackage -us -uc -rfakeroot

cargo clean

rm -rf target

DIST_NAME=jessie
FILENAME=$(basename $(ls /tmp/librespot_${PACKAGE_VERSION}*.deb))
/home/marcus/bin/dropbox_uploader.sh upload /tmp/${FILENAME} /Public/librespot/${DIST_NAME}/${ARCH}/${FILENAME}



