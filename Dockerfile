# syntax=docker/dockerfile:1.4
FROM python:3.11-slim

# Install dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

WORKDIR /app
COPY . .

# Set dbt environment directories
ENV DBT_PROFILES_DIR=/app
ENV DBT_PROJECT_DIR=/app

# Pre-download dbt packages (no secrets needed)
RUN dbt deps

# Pre-compile models using all secrets at build time
RUN --mount=type=secret,id=aws_region \
    --mount=type=secret,id=s3_key \
    --mount=type=secret,id=s3_secret \
    --mount=type=secret,id=pg_host \
    --mount=type=secret,id=pg_port \
    --mount=type=secret,id=pg_user \
    --mount=type=secret,id=pg_password \
    --mount=type=secret,id=pg_database \
    export AWS_REGION=$(cat /run/secrets/aws_region) && \
    export S3_ACCESS_KEY_ID=$(cat /run/secrets/s3_key) && \
    export S3_SECRET_ACCESS_KEY=$(cat /run/secrets/s3_secret) && \
    export POSTGRES_HOST=$(cat /run/secrets/pg_host) && \
    export POSTGRES_PORT=$(cat /run/secrets/pg_port) && \
    export POSTGRES_USER=$(cat /run/secrets/pg_user) && \
    export POSTGRES_PASSWORD=$(cat /run/secrets/pg_password) && \
    export POSTGRES_DATABASE=$(cat /run/secrets/pg_database) && \
    dbt compile

# Default entrypoint
ENTRYPOINT ["dbt"]
