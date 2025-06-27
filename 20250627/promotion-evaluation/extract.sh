#!/bin/bash

echo "Time,pgpgin/s,pgpgout/s,pgprom/s,pgdem/s"

tail -n +4 "$1" | while IFS=" " read -r time pgpgin pgpgout fault majflt pgfree pgscank pgscand pgsteal pgprom pgdem;do
    echo "$time,$pgpgin,$pgpgout,$pgprom,$pgdem"
done
