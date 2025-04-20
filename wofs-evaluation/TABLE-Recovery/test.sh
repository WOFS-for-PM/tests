#!/usr/bin/env bash

bash test-worst.sh > performance-comparison-table-worst
# fetch the last line of the output
LAST_LINE=$(tail -n 1 performance-comparison-table-worst)
echo "$LAST_LINE" > performance-comparison-table-worst
bash test-common.sh
