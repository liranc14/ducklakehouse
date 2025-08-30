# Base image with Python
FROM python:3.11-slim

# Install dependencies from requirements.txt
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Set working dir
WORKDIR /app

# Copy only needed files (honoring .dockerignore)
COPY . .

# Set dbt environment variables
ENV DBT_PROFILES_DIR=/app
ENV DBT_PROJECT_DIR=/app

# Accept build-time secrets as arguments
ARG AWS_REGION
ARG S3_ACCESS_KEY_ID
ARG S3_SECRET_ACCESS_KEY
ARG POSTGRES_HOST
ARG POSTGRES_PORT
ARG POSTGRES_USER
ARG POSTGRES_PASSWORD
ARG POSTGRES_DATABASE

# Set build args as env vars inside the container
ENV AWS_REGION=$AWS_REGION
ENV S3_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
ENV S3_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
ENV POSTGRES_HOST=$POSTGRES_HOST
ENV POSTGRES_PORT=$POSTGRES_PORT
ENV POSTGRES_USER=$POSTGRES_USER
ENV POSTGRES_PASSWORD=$POSTGRES_PASSWORD
ENV POSTGRES_DATABASE=$POSTGRES_DATABASE

# Pre-download dbt packages
RUN dbt deps

# Pre-compile all models (now has access to env vars)
RUN dbt compile

# Default command (can be overridden by docker run / ECS / EventBridge)
ENTRYPOINT ["dbt"]
