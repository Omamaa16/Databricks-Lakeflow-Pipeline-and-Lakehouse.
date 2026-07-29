-- Controlling DDLs

-- run_profile
CREATE TABLE IF NOT EXISTS olist_brazil.control.run_profile (
    run_id STRING,
    layer STRING,
    scope STRING,
    start_ts TIMESTAMP,
    end_ts TIMESTAMP,
    status STRING,
    remarks STRING
)
USING DELTA
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true'
);


-- ingestion_qaulity

CREATE TABLE IF NOT EXISTS olist_brazil.control.ingestion_quality (
    run_id                  STRING    NOT NULL,
    layer_name              STRING    NOT NULL,
    table_catalog           STRING    NOT NULL,
    table_schema            STRING    NOT NULL,
    table_name              STRING    NOT NULL,
    rescued_record_count    BIGINT    NOT NULL,
    corrupted_record_count  BIGINT    NOT NULL,
    source_file_count       BIGINT    NOT NULL,
    measured_at             TIMESTAMP NOT NULL
)
USING DELTA
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true'
);


-- table_profile

CREATE TABLE IF NOT EXISTS olist_brazil.control.table_profile (
    run_id STRING,
    table_name STRING,
    table_rows BIGINT,
    table_columns INT,
    table_schema STRING,
    table_catalog STRING,
    distinct_business_key_count BIGINT,
    duplicate_business_key_count BIGINT,
    null_business_key_count BIGINT,
    run_ts TIMESTAMP
)
USING DELTA
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true'
);


/*duplicate keys
only the table 'geolocation' had duplicates, hence, a duplicate table for this table only.*/

CREATE TABLE IF NOT EXISTS olist_brazil.control.duplicate_keys (
    profile_run_id STRING,
    profile_run_ts TIMESTAMP,
    layer_name STRING,
    table_name STRING,
    key_column STRING,
    key_value STRING,
    duplicate_count BIGINT
)
USING DELTA
TBLPROPERTIES (
    'quality' = 'control',
    'delta.enableChangeDataFeed' = 'true'
);
