#!/bin/bash
# This script is meant to be executad inside the `app` container

OUTPUT_DIR=/app/results/
REPORT_DIR=/app/report/
DATASETS_DIR=/app/datasets/
MONGODB_URI=mongodb://mongo:27017/testDatabase

### Dispatch the experiments
function run_one_dataset() {
    local input_file="$1"
    local collection_name="$2"

    echo >&2 "[INFO] Importing $input_file into collection $collection_name"
    mongoimport --uri=$MONGODB_URI \
        --collection=$collection_name \
        --file=$input_file \
        --jsonArray \
        --drop

    echo >&2 "[INFO] Running test script"
    output=$(
        MONGODB_URI=$MONGODB_URI \
            OUTPUT_DIR=$OUTPUT_DIR \
            DATABASE_NAME=testDatabase \
            COLLECTION_NAME=$collection_name \
            node /app/scripts/index.cjs
    )
}

### Evaluate the experiments
function get_result() {
    local batch_id="$1"
    local dataset="$2"
    local batch_info="$OUTPUT_DIR/batchInfo_$batch_id.json"

    if [ -f $batch_info ]; then
        local count=$(jq .collectionCount $batch_info)
        local unordered=$(jq .uniqueUnorderedCount $batch_info)
        local ordered=$(jq .uniqueOrderedCount $batch_info)
        echo "\\def\\${dataset}Count{$count} \
        \\def\\${dataset}Unordered{$unordered} \
        \\def\\${dataset}Ordered{$ordered}" >>"${REPORT_DIR}params.inc"
    else
        echo >&2 "$batch_id"
        echo >&2 "[ERROR] BatchInfo does not exist"
        exit 1
    fi
}

echo "" >"${REPORT_DIR}params.inc"
datasets=("companies" "drugs" "movies")
for dataset in "${datasets[@]}"; do
    extracted_json="$(ls ${DATASETS_DIR}dbpedia*${dataset}*.json)"
    echo >&2 "[INFO] Running on $extracted_json"

    run_one_dataset $extracted_json $dataset
    get_result $output $dataset
done

### Generate the report
make clean -C $REPORT_DIR
make report -C $REPORT_DIR
