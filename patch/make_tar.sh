#!/bin/sh

DATE=$(date +%d%m%y)
LINUX=linux-2.6.31

TARFILE=~/snapshot-$DATE.tgz

cd ../..
tar cvfz $TARFILE --exclude=.svn snapshot/{bin,docs,$LINUX,patch/*.{sh,sed}}

