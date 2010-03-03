#!/bin/sh

DATE=$(date +%d%m%y)
LINUX=linux-2.6.31
E2FS=e2fsprogs-1.41.9

TARFILE=~/snapshot-$DATE.tar.gz

cd ../..
tar cvfz $TARFILE --exclude=.svn snapshot/{bin,docs,$LINUX,$E2FS,patch/Makefile,patch/*.{sh,sed,c}}

