#!/bin/sh

DATE=$(date +%d%m%y)
LINUX=linux-2.6.31
E2FS=e2fsprogs-1.41.9

if [ -z $1 ] || [ $1 = snapshot ] ; then
	# add snapshot to fresh next3 clone
	PATCHNAME=next3_snapshot
	RELEASE=next3_snapshot-$DATE
	ORIG=$LINUX.next3
	SRC=$LINUX
elif [ $1 = linux ] || [ $1 = kernel ] ; then
	# add next3+snapshot to kernel
	PATCHNAME=next3_fs
	RELEASE=${LINUX}_next3-$DATE
	ORIG=$LINUX.orig
	SRC=$LINUX
elif [ $1 = e2fs ] || [ $1 = user ] ; then
	PATCHNAME=e2fs_next3
	RELEASE=${E2FS}_next3-$DATE
	ORIG=$E2FS.orig
	SRC=$E2FS
else
	echo usage: $0 [snapshot|linux|kernel|e2fs|user]
	exit 1
fi

if [ $SRC = $LINUX ] ; then
	mkdir -p $LINUX/include/linux
	mkdir -p $LINUX/fs/jbd
	mkdir -p $LINUX/fs/next3
elif [ $SRC = $E2FS ] ; then
	mkdir -p $E2FS/lib/e2p
	mkdir -p $E2FS/lib/ext2fs
	mkdir -p $E2FS/lib/e2fsck
	mkdir -p $E2FS/resize
	mkdir -p $E2FS/debugfs
	mkdir -p $E2FS/misc
fi

for f in $(cd .. && ls -d $SRC/*/* && ls -d $SRC/*/*/*) ; do 
	(test -f ../$f && echo updating $f... && cp -f ../$f $f)
done

diff -Nuarp -X .ignore $ORIG $SRC > $PATCHNAME.patch

cp $PATCHNAME.patch ~/$RELEASE.patch
