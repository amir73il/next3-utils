#!/bin/sh

DATE=$(date +%d%m%y)
LINUX=linux-2.6.31

if [ ! -z $1 ] && [ $1 = kernel ] ; then
	# add next3+snapshot to kernel
	PATCHNAME=next3_fs
	ORIG=$LINUX.orig
else
	# add snapshot to fresh next3 clone
	PATCHNAME=next3_snapshot
	ORIG=$LINUX.next3
fi

PATCHDATE=$PATCHNAME-$DATE

mkdir -p $LINUX/include/linux
mkdir -p $LINUX/fs/jbd
mkdir -p $LINUX/fs/next3

for f in $(cd .. && ls -d $LINUX/*/* && ls -d $LINUX/*/*/*) ; do 
	(test -f ../$f && echo updating $f... && cp -u ../$f $f)
done

diff -Nuar --exclude=tags $ORIG $LINUX > $PATCHNAME.patch

cp $PATCHNAME.patch ~/$PATCHDATE.patch
