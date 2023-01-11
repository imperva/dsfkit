#!/bin/bash -x -e

lock_file_prefix=lock-file
lock_file=$lock_file_prefix-$RANDOM-$RANDOM-$RANDOM

trap "rm -f $lock_file" EXIT
lock_acquired=0
while [ $lock_acquired -eq 0 ]; do
    rm -f $lock_file
    while ls $lock_file_prefix* &>/dev/null; do
        rm -f $lock_file
        echo "waiting for previous federation to complete.."
        sleep $(($RANDOM * 100 / 100000))
    done
    touch $lock_file
    sleep 0.2
    lock_files=$(ls $lock_file_prefix* 2>/dev/null | wc -l)
    if [ "$lock_files" -eq 1 ]; then
        lock_acquired=1
    fi
done
