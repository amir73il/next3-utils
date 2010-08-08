#!/bin/sh

DATE=$(date +%d%m%y)
LINUX=linux-2.6.31.11
E2FS=e2fsprogs-1.41.9
PKG=snapshot

TARFILE=~/$PKG-$DATE.tar.gz

cd ../..
test -e $PKG || ln -sf next3 $PKG
tar cvhfz $TARFILE --exclude=.svn $PKG/{Makefile,bin,docs,$LINUX,$E2FS,rebase,patch/Makefile,patch/*.{sh,c}}

