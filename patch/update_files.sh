#!/bin/sh
# update changed files from 'src' to 'dst' directory
# changed files are copied to dst directory with
# current modification time (now)
# 'test' only lists different files
# 'diff' shows the differences
# 'back' updates from 'dst' to 'src'

if [ $# -lt 2 ] ; then
	echo 'usage: ' $0 '<src> <dst> [test|diff|back]'
	exit 1
fi

SRC=$1
DST=$2

TEST='diff -q'
if [ update_$3 = update_test ] ; then
	UPDATE='diff -q'
	FROM=$SRC
	TO=$DST
elif [ update_$3 = update_diff ] ; then
	UPDATE='diff -u'
	FROM=$SRC
	TO=$DST
elif [ update_$3 = update_back ] ; then
	UPDATE='cp -f'
	FROM=$DST
	TO=$SRC
else
	UPDATE='cp -f'
	FROM=$SRC
	TO=$DST
fi

files=$(cd $SRC && ls -d * && ls -d */* && ls -d */*/*)
for f in $files ; do 
	(test -f $SRC/$f && test -f $DST/$f && \
	( $( $TEST $SRC/$f $DST/$f > /dev/null ) || \
	(echo updating $f... && $UPDATE $FROM/$f $TO/$f)))
done
