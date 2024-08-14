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
dbt run --target-path target/run --exclude tag:static
RUN_EXIT_CODE=$?

# If run command failed. Exit early
if [ $RUN_EXIT_CODE -ne 0 ]; then
  echo "dbt run failed"
  exit $RUN_EXIT_CODE
fi

# Run tests
dbt test --target-path target/test
TEST_EXIT_CODE=$?

# exit with the test exit code
echo "dbt run complete"
exit $TEST_EXIT_CODE