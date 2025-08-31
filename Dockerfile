FROM python:3.11-slim


COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

WORKDIR /app
COPY . .

# Set dbt environment directories
ENV DBT_PROFILES_DIR=/app
ENV DBT_PROJECT_DIR=/app


RUN dbt deps


ENTRYPOINT ["dbt"]
