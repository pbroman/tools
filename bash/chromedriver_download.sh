#!/usr/bin/env bash
#
# A very simple script for Gitbash, downloading the latest stable chromedriver
# and replacing .vaadin/drivers with the unpacked driver
#
# Use at own risk! :)
# Prerequisite: jq is installed

set -e

WORKDIR=$(pwd)/workdir
CHROMELABS_URL="https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions.json"
VERSION=$(curl $CHROMELABS_URL | jq -r .channels.Stable.version)
DOWNLOAD_URL="https://storage.googleapis.com/chrome-for-testing-public/${VERSION}/win64/chromedriver-win64.zip"
OUTPUT="$WORKDIR/latest_chromedriver.zip"
TARGET="/c/Users/$(whoami)/.vaadin/drivers"

rm -rf $WORKDIR
mkdir -p $WORKDIR

echo "Last known stable version: $VERSION"
echo "Downloading from $DOWNLOAD_URL"
echo "Saving to $OUTPUT"
curl $DOWNLOAD_URL --output $OUTPUT

echo "Unzipping"
unzip $OUTPUT -d $WORKDIR

echo "Replacing driver"
set -x
rm -rf "${TARGET}_old"
mv ${TARGET} "${TARGET}_old"
mv $WORKDIR/chromedriver-win64 ${TARGET}

rm -rf $WORKDIR