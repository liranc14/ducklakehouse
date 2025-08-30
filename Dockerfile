# Base image with Python
FROM python:3.11-slim

# Install dependencies from requirements.txt
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Set working dir
WORKDIR /app

# Copy only needed files (honoring .dockerignore)
COPY . .

ENV DBT_PROFILES_DIR=/app
ENV DBT_PROJECT_DIR=/app

# Pre-download dbt packages
RUN dbt deps

# Pre-compile all models
RUN dbt compile

# Default command (can be overridden by ECS/EventBridge)
ENTRYPOINT ["dbt"]
