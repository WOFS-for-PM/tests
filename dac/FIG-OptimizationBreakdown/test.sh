#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"

bash test-workload.sh
bash test-lose-layout.sh
bash test-tight-layout.sh

