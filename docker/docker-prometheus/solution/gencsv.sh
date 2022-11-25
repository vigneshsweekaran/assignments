#!/bin/bash

RANDOM=$$
NO_OF_ENTRIES=9

if [[ -f inputFile ]]; then rm -f inputdata; fi
for i in `seq 0 $NO_OF_ENTRIES`; do
    echo "$i, $RANDOM" >> inputdata
done
