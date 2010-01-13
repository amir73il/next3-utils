#!/bin/sh
# compile each patch separately
# Erez Zadok, 2009

function runcmd
{
    echo "CMD: $@"
    sleep 0.25
    $@
    ret=$?
    if test $ret -ne 0 ; then
	exit $ret
    fi
}

runcmd guilt-pop $1 # pass $1="-a" ?
runcmd make -j 4 ARCH=i386
for i in `guilt-series`; do
    runcmd guilt-push
    runcmd make -j 4 ARCH=i386
done
