

## create file ~/.duckdbrc

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