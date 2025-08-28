# Base image with Python
FROM python:3.11-slim

# Install dbt-duckdb
RUN pip install --no-cache-dir dbt-duckdb==1.9.4

# Set working dir
WORKDIR /app

# Copy only needed files (honoring .dockerignore)
COPY . .

ENV DBT_PROFILES_DIR=/app
ENV DBT_PROJECT_DIR=/app

# Default command (can be overridden by ECS/EventBridge)
ENTRYPOINT ["dbt"]
