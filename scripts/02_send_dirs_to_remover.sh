#!/usr/bin/env bash

source .env

$ENV_PATH=/usr/local/lib/logs_archiver_$SERVICE_POSTFIX/.env

while IFS= read -r dir; do
    echo "=== $dir ==="
    ./scripts/03_last_dirs.sh "$dir" "$NUM_LAST_DIRS" "$NUM_LAST_ARCS" "$ENV_PATH"
    echo
done
