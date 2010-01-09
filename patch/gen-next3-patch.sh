#!/bin/sh
# generate a Next3 patch against 2.6.31.y,
# and one against vanilla ext3 (which was just renamed to "next3")

if ! test -d .git || ! test -f fs/next3/next3.h
then
    echo Please run $0 from the top-level Linux source tree directory
    exit 1
fi
all="next3-`date +%F`-full.patch"
file="next3-`date +%F`-ext3.patch"

echo "git diff ':/Linux 2.6.31.9'.. > $all"
mv -f $all $all.old 2> /dev/null
git diff ':/Linux 2.6.31.9'.. > $all || exit $?
diffstat $all

echo "git diff ':/patch copy-ext3-to-next3.patch'.. > $file"
mv -f $file $file.old 2> /dev/null
git diff ':/patch copy-ext3-to-next3.patch'.. > $file || exit $?
diffstat $file
