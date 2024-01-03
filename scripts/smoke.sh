#!/bin/bash
# This script is meant to be executad inside the `app` container

INPUT_FILE=${1:-"/app/data/firenze_venues.json"}
OUTPUT_DIR=/app/results/
MONGODB_URI=mongodb://mongo:27017/testDatabase

echo "Waiting for server starts"
sleep 2

# Import test data into MongoDB
mongoimport --uri $MONGODB_URI \
    -c testCollection \
    $INPUT_FILE

# Run the test script
OUTPUT=$(MONGODB_URI=$MONGODB_URI \
    OUTPUT_DIR=$OUTPUT_DIR \
    node /app/scripts/index.cjs)

# Check if result exists
if [ -f "$OUTPUT_DIR/batchInfo_$OUTPUT.json" ]; then
    echo "Smoke test successful"
    exit 0
else
    echo "$OUTPUT_DIR/batchInfo_$OUTPUT.json does not exist"
    exit 1
fi
