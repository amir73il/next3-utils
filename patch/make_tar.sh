#!/bin/sh

DATE=$(date +%d%m%y)
LINUX=linux-2.6.31.11
E2FS=e2fsprogs-1.41.9
NEXT3=next3-1.0.9

TARFILE=~/$NEXT3-$DATE.tar.gz

cd ../..
test -e $NEXT3 || ln -sf next3 $NEXT3
tar cvhfz $TARFILE --exclude=.svn $NEXT3/{bin,docs,$LINUX,$E2FS,patch/Makefile,patch/*.{sh,c}}

