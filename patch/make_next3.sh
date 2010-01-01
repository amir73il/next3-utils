#!/bin/sh
# clone next3 fs from ext3 fs

LINUX=linux-2.6.31

if [ ! -z $1 ] && [ $1 = kernel ] ; then
	# kernel orig files
	ORIG=$LINUX.orig
else
	# kernel with fresh next3 clone
	ORIG=$LINUX.next3
fi


if [ ! -d $ORIG ] ; then 
	# first time only - copy in files about to be copied out
	mkdir -p $ORIG/include/linux
	mkdir -p $ORIG/fs
	cp -f ../../../source/$LINUX/include/linux/jbd.h $ORIG/include/linux/
	cp -f ../../../source/$LINUX/include/linux/magic.h $ORIG/include/linux/
	cp -f ../../../source/$LINUX/include/linux/buffer_head.h $ORIG/include/linux/
	cp -f ../../../source/$LINUX/include/linux/journal_head.h $ORIG/include/linux/
	cp -f ../../../source/$LINUX/fs/Makefile $ORIG/fs/
	cp -f ../../../source/$LINUX/fs/Kconfig $ORIG/fs/
	cp -f ../../../source/$LINUX/fs/buffer.c $ORIG/fs/
fi

if [ -z $1 ] || [ $1 != kernel ] ; then
	mkdir -p $ORIG/fs/next3

	cp -f ../../../source/$LINUX/fs/ext3/* $ORIG/fs/next3/
	cp -f ../../../source/$LINUX/include/linux/ext3* $ORIG/fs/next3/
	sed -i -f next3.sed $ORIG/fs/next3/*

	for X in .h _i.h _sb.h ; do
		mv -f $ORIG/fs/next3/ext3_fs$X $ORIG/fs/next3/next3$X
	done
	for X in .h .c ; do
		mv -f $ORIG/fs/next3/ext3_jbd$X $ORIG/fs/next3/next3_jbd$X
	done
	sed -i -f next3_fs.sed $ORIG/fs/next3/*
fi
