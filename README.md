# DuckLakehouse Project

DuckLakehouse is a modern lakehouse architecture leveraging dbt, DuckDB, S3, and Postgres for scalable data transformation and management. This project is designed to run both locally and in the cloud, using containerized compute resources and automated CI/CD workflows.

## Environment Setup

Before running the project, export the following environment variables:

```
AWS_REGION=xxx
S3_ACCESS_KEY_ID=xxx
S3_SECRET_ACCESS_KEY=xxx
POSTGRES_HOST=xxx
POSTGRES_PORT=xxx
POSTGRES_USER=xxx
POSTGRES_PASSWORD=xxx
POSTGRES_DATABASE=xxx

# for local if values saved in .env file:
# export $(cat .env | grep -v '^#' | xargs)
```

## S3 Bucket Configuration

The S3 bucket name is specified in `profiles.yml` and **must exist** before running the project. In this case, the bucket name is:

```
ducklakehouse
```

## CI/CD Process

A Continuous Deployment (CD) process is set up to build a Docker image of the dbt project on every change. This ensures that all transformations and dependencies are up-to-date and ready for deployment.
All aforementioned environment variables need to set as secrets in the GitHub repository, as well as GHCR_PAT - GitHub personal access token


## dbt Workflows

For every new dbt workflow, you need to create a corresponding GitHub workflow file. Example workflow:

```yaml
name: first dbt Job

on:
  schedule:
    - cron: '45 * * * *'
  workflow_dispatch:

jobs:
  run-dbt-container:
    runs-on: ubuntu-latest
    env:
      AWS_REGION: ${{ secrets.AWS_REGION }}
      S3_ACCESS_KEY_ID: ${{ secrets.S3_ACCESS_KEY_ID }}
      S3_SECRET_ACCESS_KEY: ${{ secrets.S3_SECRET_ACCESS_KEY }}
      POSTGRES_HOST: ${{ secrets.POSTGRES_HOST }}
      POSTGRES_PORT: ${{ secrets.POSTGRES_PORT }}
      POSTGRES_USER: ${{ secrets.POSTGRES_USER }}
      POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }}
      POSTGRES_DATABASE: ${{ secrets.POSTGRES_DATABASE }}

    steps:
      - name: Checkout code (optional, if needed)
        uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_PAT }}

      - name: Run dbt container
        run: |
          docker run --rm \
            -e AWS_REGION \
            -e S3_ACCESS_KEY_ID \
            -e S3_SECRET_ACCESS_KEY \
            -e POSTGRES_HOST \
            -e POSTGRES_PORT \
            -e POSTGRES_USER \
            -e POSTGRES_PASSWORD \
            -e POSTGRES_DATABASE \
            ghcr.io/liranc14/ducklakehouse:latest run -s first_team_model
```

## How dbt Runs Work

Any `dbt run` will:
- Connect to the specified S3 bucket and Postgres metadata.
- Use DuckLake for lakehouse management.
- Leverage container compute resources and the DuckDB engine for transformations.
- Materialize the output in the S3 bucket (`ducklakehouse`).

## Local Connectivity Instructions

To connect locally, create the file `~/.duckdbrc` with the following content:

```
INSTALL ducklake;
INSTALL postgres;
INSTALL httpfs;
INSTALL parquet;
LOAD ducklake;
LOAD postgres;
LOAD httpfs;
LOAD parquet;
CREATE SECRET my_dlh (TYPE S3, PROVIDER config, KEY_ID {{S3_ACCESS_KEY_ID}}, SECRET {{S3_SECRET_ACCESS_KEY}}, REGION {{AWS_REGION}}, USE_SSL true);
ATTACH 'ducklake:postgres:dbname={{POSTGRES_DATABASE}} host={{POSTGRES_HOST}} port={{POSTGRES_PORT}} user={{POSTGRES_USER}} password={{POSTGRES_PASSWORD}}' as ducklake_test(DATA_PATH 's3://{{BUCKET_NAME}}');
use ducklake_test;
CALL start_ui();
```

Replace the placeholders with your actual environment variables or export them as mentioned in `Environment Setup`. This will set up your local DuckDB environment to interact with S3 and Postgres using DuckLake.

---
