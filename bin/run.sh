#!/bin/sh

DIR=$(cd "$1" && pwd)

./bin/ssw.pl $DIR

fswatch -0 -r $DIR | xargs -0 -n1 -I{} ./bin/ssw.pl $DIR
