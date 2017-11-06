#!/bin/sh

CURDIR=`dirname "$0"`
TOP=$(cd $CURDIR/.. && pwd)
DIR=$(cd "$1" && pwd)

$TOP/bin/ssw.pl workflow $DIR

fswatch -0 -r $DIR | xargs -0 -n1 -I{} $TOP/bin/ssw.pl workflow $DIR
