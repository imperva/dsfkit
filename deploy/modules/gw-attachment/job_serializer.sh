#!/bin/bash
set -e

index=${index}
queue_file=queue-file


if [ $index -eq 0 ]; then
    echo 0 > $queue_file
fi

while [ ! -f $queue_file ]; do
    echo "waiting $queue_file to be created"
    sleep 1
done

while [ $(cat $queue_file) -ne $index ]; do
    sleep 10
    echo "waiting for previous federation to complete.."
done

trap "echo $((1 + $index)) > $queue_file" EXIT