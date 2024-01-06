# Replication Package for "JSONSchemaDiscovery"

This repository provides the replication package for the research "JSONSchemaDiscovery"

## Prerequisites

- `Docker` is needed for server deployment.

## Performing measurements

After cloning the repository, follow the steps to perform the measurements:

- Launch the servers
  ```
  docker compose up -d
  ```
- Enter the container interactively
  ```
  docker exec -it app bash
  ```
- Run the script to perform an evaluation, results will be stored at `/app/results`
  ```
  ./scripts/smoke.sh
  ```

## Build the report

After evaluating the results, follow the steps to build the LaTeX report:

- Enter the report directory
  ```
  cd /app/report
  ```
- Run the Makefile to build report
  ```
  make report
  ```
- Clean build cache
  ```
  make clean
  ```
