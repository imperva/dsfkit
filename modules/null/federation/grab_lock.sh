#!/bin/bash
set -x -e

lock_file_prefix=lock-file
lock_file=$lock_file_prefix-$RANDOM-$RANDOM-$RANDOM
trap "rm -f $lock_file" EXIT
lock_acquired=0
while [ $lock_acquired -eq 0 ]; do
    rm -f $lock_file
    while ls $lock_file_prefix* &>/dev/null; do
        rm -f $lock_file
        echo "waiting for previous federation to complete.."
        sleep "$(( ( RANDOM * 100 ) / 100000 ))"
    done
    touch $lock_file
    # TODO write to the file which federation touched it, i.e., hub ip -> gw ip
    echo "touched $lock_file"
    # sleep between 0.2 and 0.5 seconds
    sleep "0.$(( ( ( RANDOM * 10 ) / 100000 ) + 2 ))"
    lock_files=("$lock_file_prefix"*)
    if [[ "${#lock_files[@]}" == "1" ]]; then
        lock_acquired=1
    fi
done