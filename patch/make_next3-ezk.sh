#!/bin/sh
# clone next3 fs from ext3 fs

LINUX=linux-2.6.31-ezk
ORIG=$LINUX

mkdir -p $ORIG/fs/next3

cp -f $LINUX/fs/ext3/* $ORIG/fs/next3/
cp -f $LINUX/include/linux/ext3* $ORIG/fs/next3/
sed -i -f next3.sed $ORIG/fs/next3/*

for X in .h _i.h _sb.h ; do
	mv -f $ORIG/fs/next3/ext3_fs$X $ORIG/fs/next3/next3$X
done
for X in .h .c ; do
	mv -f $ORIG/fs/next3/ext3_jbd$X $ORIG/fs/next3/next3_jbd$X
done
sed -i -f next3_fs.sed $ORIG/fs/next3/*
