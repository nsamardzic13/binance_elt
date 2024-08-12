#!/bin/bash

SERVICE_ACCOUNT_JSON_PATH=/root/service-account.json
# ECS injects the SERVICE_ACCOUNT_JSON as a stringified JSON object
if [ -z "$SERVICE_ACCOUNT_JSON" ]; then
  echo "SERVICE_ACCOUNT_JSON is not set"
  exit 1
else
  # Save the SERVICE_ACCOUNT_JSON to a file
  echo $SERVICE_ACCOUNT_JSON > $SERVICE_ACCOUNT_JSON_PATH
  # export the SERVICE_ACCOUNT_JSON_PATH so the dbt project can read it
  export SERVICE_ACCOUNT_JSON_PATH=$SERVICE_ACCOUNT_JSON_PATH
fi

# # Perform some variable checks
# if [ -z "$ARTIFACT_BUCKET_NAME" ]; then
#   echo "ARTIFACT_BUCKET_NAME is not set"
#   exit 1
# fi
# if [ -z "$S3_STORAGE_PREFIX" ]; then
#   S3_STORAGE_PREFIX="dbt"
# fi

# Setup and install packages
cd dbt_binance
mkdir -p target/run && mkdir -p target/test

dbt deps

# Run dbt
dbt run --target-path target/run
RUN_EXIT_CODE=$?

# # Copy artifacts to S3
# aws s3 cp target/run/manifest.json s3://$ARTIFACT_BUCKET_NAME/$S3_STORAGE_PREFIX/$ORCHESTRA_TASK_RUN_ID/run/manifest.json
# aws s3 cp target/run/run_results.json s3://$ARTIFACT_BUCKET_NAME/$S3_STORAGE_PREFIX/$ORCHESTRA_TASK_RUN_ID/run/run_results_1.json

# If run command failed. Exit early
if [ $RUN_EXIT_CODE -ne 0 ]; then
  echo "dbt run failed"
  exit $RUN_EXIT_CODE
fi

# Run tests
dbt test --target-path target/test
TEST_EXIT_CODE=$?

# # Copy artifacts to S3
# aws s3 cp target/test/manifest.json s3://$ARTIFACT_BUCKET_NAME/$S3_STORAGE_PREFIX/$ORCHESTRA_TASK_RUN_ID/test/manifest.json
# aws s3 cp target/test/run_results.json s3://$ARTIFACT_BUCKET_NAME/$S3_STORAGE_PREFIX/$ORCHESTRA_TASK_RUN_ID/test/run_results_2.json

# exit with the test exit code
echo "dbt run complete"
exit $TEST_EXIT_CODE