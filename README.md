# Replication Package for "JSONSchemaDiscovery"

This repository provides the replication package for the research "JSONSchemaDiscovery"

## Prerequisites

- `Docker` is needed for server deployment.
- A minimum of 4GB of memory is required to launch the containers.

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
- Run the script to perform an evaluation and build the report
  ```
  ./scripts/doAll.sh
  ```

The extracted results will be stored at `/app/results`. The report will be stored at `/app/report/obj/main.pdf`

## Build the report

User can manually build the LaTeX report after performing measurements:

- Enter the report directory
  ```
  cd /app/report
  ```
- Run the Makefile to build report, the result will be stored at `/app/report/obj/main.pdf`
  ```
  make report
  ```
- Clean build cache
  ```
  make clean
  ```
