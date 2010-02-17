#!/bin/sh
# clone next3 fs from ext3 fs

LINUX=linux-2.6.32.8
PATCHNAME=next3_fs

# kernel orig files
ORIG=$LINUX.orig
# kernel with fresh next3 clone
SRC=$LINUX.next3

if [ ! -d $ORIG ] ; then 
	# first time only - copy in files about to be copied out
	mkdir -p $ORIG/include/linux
	mkdir -p $ORIG/fs
	cp -f ../../../source/$LINUX/include/linux/jbd.h $ORIG/include/linux/
	cp -f ../../../source/$LINUX/include/linux/magic.h $ORIG/include/linux/
	cp -f ../../../source/$LINUX/include/linux/buffer_head.h $ORIG/include/linux/
	cp -f ../../../source/$LINUX/include/linux/journal-head.h $ORIG/include/linux/
	cp -f ../../../source/$LINUX/fs/Makefile $ORIG/fs/
	cp -f ../../../source/$LINUX/fs/Kconfig $ORIG/fs/
	cp -f ../../../source/$LINUX/fs/buffer.c $ORIG/fs/
fi

if [ ! -d $SRC ] ; then 
	cp -a $ORIG $SRC
	mkdir -p $SRC/fs/next3

	cp -f ../../../source/$LINUX/fs/ext3/* $SRC/fs/next3/
	cp -f ../../../source/$LINUX/include/linux/ext3* $SRC/fs/next3/
	sed -i -f next3.sed $SRC/fs/next3/*

	for X in .h _i.h _sb.h ; do
		mv -f $SRC/fs/next3/ext3_fs$X $SRC/fs/next3/next3$X
	done
	for X in .h .c ; do
		mv -f $SRC/fs/next3/ext3_jbd$X $SRC/fs/next3/next3_jbd$X
	done
	sed -i -f next3_fs.sed $SRC/fs/next3/*
fi

diff -Nuarp -X .ignore $ORIG $SRC > $PATCHNAME.patch
