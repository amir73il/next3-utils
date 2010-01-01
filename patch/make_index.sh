#!/bin/sh

echo running $0 $1...

DATE=$(date +%d%m%y)
LINUX=linux-2.6.31

INDEXNAME=next3_index
MAINKEY=CONFIG_NEXT3_FS_SNAPSHOT
INDEXDATE=~/$INDEXNAME-$DATE.csv
KEY=$1
GREP=grep

if [ -z $1 ] ; then
	for f in $(cd .. && ls -d $LINUX/*/* && ls -d $LINUX/*/*/*) ; do 
		(test -f ../$f && echo updating $f... && cp -u ../$f $f)
	done
	rm -f $LINUX/*/*/tags
	cp -f ../docs/INDEX $INDEXNAME
	INDEXKEYS=next3_keys
	rm -f $INDEXKEYS $INDEXKEYS.* $INDEXNAME.*
	echo > $INDEXNAME.
else
	INDEXKEYS=next3_keys.$KEY
fi

if [ -z $1 ] ; then
	# generate index keys from Kconfig
	$GREP -A 1 "config NEXT3_FS_SNAPSHOT_" $LINUX/fs/next3/Kconfig > next3_config
	while read cmd line ; do 
		case "$cmd" in
			config)
				echo $line | tr "_" " " | while read NEXT3 FS SNAPSHOT key subkey ; do
					if [ -z $subkey ] ; then
						echo _$key >> $INDEXKEYS
						echo -n ${MAINKEY}_${key} - >> $INDEXNAME.
						echo -n > $INDEXKEYS._$key
						echo -n > $INDEXNAME._$key
						test -e $INDEXNAME._ && rm $INDEXNAME._
						ln $INDEXNAME._$key $INDEXNAME._
					else
						echo _$key _$subkey >> $INDEXKEYS._$key
						echo -n ${MAINKEY}_${key}_${subkey} - >> $INDEXNAME._
					fi
				done
				;;
			bool)
				if [ ! -s $INDEXNAME._ ] ; then
					echo $line | tr "\"" " " >> $INDEXNAME.
					echo >> $INDEXNAME._
				else
					echo $line | tr "\"" " " >> $INDEXNAME._
				fi
				;;
			*)
				;;
		esac
	done < next3_config
fi

files=$( cd $LINUX && ls -d */* && ls -d */*/* )

if [ -f $INDEXKEYS ] ; then
echo
echo ${MAINKEY}${KEY} patch categories:
cat $INDEXNAME.$KEY
echo
echo Number of patch hunks per category/file:
echo
# print index keys at table header row
echo -n ${MAINKEY}${KEY}
while read key subkey ; do
	if [ -z $1 ] ; then
		echo -n ',' $key
		echo -n '*'
	else
		echo -n ',' $subkey
	fi
done < $INDEXKEYS
if [ ! -z $1 ] ; then
	echo -n ', '
fi
echo -n ', *'
echo

cd $LINUX
# print table row per file
for f in $files ; do 
	N=$( $GREP ${MAINKEY}${KEY} $f | wc -l )
	n0=$N
	if [ $N != 0 ] ; then
		echo -n $f
		while read key subkey ; do
			n=$( $GREP ${MAINKEY}${key}${subkey} $f | wc -l )
			echo -n ',' $n
			n0=$[ $n0 - $n ]
		done < ../$INDEXKEYS
		if [ ! -z $1 ] ; then
			echo -n ',' $n0
		fi
		echo -n ',' $N
		echo
	fi
done
# print the Total row
N=$( $GREP ${MAINKEY}${KEY} $files | wc -l )
n0=$N
if [ $N != 0 ] ; then
	echo -n 'Total'
	while read key subkey ; do
		n=$( $GREP ${MAINKEY}${key}${subkey} $files | wc -l )
		echo -n ',' $n
		n0=$[ $n0 - $n ]
	done < ../$INDEXKEYS
	if [ ! -z $1 ] ; then
		echo -n ',' $n0
	fi
	echo -n ',' $N
	echo
fi
cd ..
echo
fi >> $INDEXNAME

# run script again for every subkey
if [ -z $1 ] ; then
while read key ; do
	$0 $key
done < $INDEXKEYS

cp $INDEXNAME $INDEXDATE
unix2dos $INDEXDATE
fi
