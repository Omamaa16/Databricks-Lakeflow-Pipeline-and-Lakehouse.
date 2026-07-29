-- Controlling tables DDL.


CREATE TABLE IF NOT EXISTS olist_brazil.control.run_profile (
    run_id              STRING    NOT NULL,
    layer_name          STRING    NOT NULL,
    scope_name          STRING    NOT NULL,
    started_at          TIMESTAMP NOT NULL,
    completed_at        TIMESTAMP,
    run_status          STRING    NOT NULL,
    remarks             STRING,
    created_at          TIMESTAMP NOT NULL,
    updated_at          TIMESTAMP NOT NULL
)
USING DELTA
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true'
);


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


CREATE TABLE IF NOT EXISTS olist_brazil.control.table_profile (
    run_id                       STRING    NOT NULL,
    layer_name                   STRING    NOT NULL,
    table_catalog                STRING    NOT NULL,
    table_schema                 STRING    NOT NULL,
    table_name                   STRING    NOT NULL,
    table_row_count              BIGINT    NOT NULL,
    table_column_count           BIGINT    NOT NULL,
    valid_business_key_count     BIGINT    NOT NULL,
    distinct_business_key_count  BIGINT    NOT NULL,
    duplicate_business_key_count BIGINT    NOT NULL,
    null_business_key_count      BIGINT    NOT NULL,
    profiled_at                  TIMESTAMP NOT NULL
)
USING DELTA
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true'
);


CREATE TABLE IF NOT EXISTS olist_brazil.control.duplicate_keys (
    run_id           STRING    NOT NULL,
    profiled_at      TIMESTAMP NOT NULL,
    layer_name       STRING    NOT NULL,
    table_catalog    STRING    NOT NULL,
    table_schema     STRING    NOT NULL,
    table_name       STRING    NOT NULL,
    key_columns      STRING    NOT NULL,
    key_value        STRING    NOT NULL,
    duplicate_count  BIGINT    NOT NULL
)
USING DELTA
TBLPROPERTIES (
    'delta.enableChangeDataFeed' = 'true'
);
