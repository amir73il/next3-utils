#!/bin/sh
# generate a Next3 patch

if ! test -d .git || ! test -f fs/next3/next3.h
then
    echo Please run $0 from the top-level Linux source tree directory
    exit 1
fi
file="next3-`date +%F`.patch"
echo "git diff master_base.. > $file"
git diff master_base.. > $file || exit $?
diffstat $file
