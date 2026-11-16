#!/bin/bash
# usage: ./report.sh access.log
log=$1
if [ -z "$log" ] || [ ! -f "$log" ]; then
    echo "no such file: $log" >&2
    echo "usage: $0 <logfile>" >&2
    exit 1
fi
total=$(wc -l < "$log")
fails=$(grep -c FAIL "$log")
echo "$total requests, $fails failed"
for n in 0 1 2 3 4 5 6; do
    cnt=$(grep " user$n " "$log" | grep -c FAIL)
    echo "user$n: $cnt failures"
done
