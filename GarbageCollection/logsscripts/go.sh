#!/bin/bash
FILES=./1*
for f in $FILES
do
  perl parselogs.pl $f
done
