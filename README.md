# Databricks-Lakeflow-Pipeline-and-Lakehouse.
Medallion Architecture | Delta Lake | Auto Loader | Streaming Ingestion | Dimensional Modeling | SCD Type 2 | Data Quality | Monitoring

## About
An end-to-end data engineering project that transforms raw Brazilian e-commerce data into a governed, analytics-ready dimensional data warehouse using Databricks, Delta Lake, Lakeflow Declarative Pipelines, Spark SQL, Streaming Tables, Volumes, Materialized Views, and Workflow jobs.

The solution implements the Medallion Architecture, incremental ingestion, data-quality controls, SCD1, SCD2, surrogate-key management, fact tables, audit logging, and production-oriented pipeline orchestration.

The project uses the Olist Brazilian E-Commerce Dataset, containing:

- Customers
- Orders
- Order items
- Products
- Sellers
- Payments
- Reviews
- Geographical locations
- Product-category translations

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## Architecture
<img width="891" height="235" alt="image" src="https://github.com/user-attachments/assets/62352a5a-2d90-4354-ae9a-0cb6af58686d" />

## Medallion Architecture
### Bronze Layer

The Bronze layer ingests raw CSV files incrementally using Databricks streaming tables.

The original source values are initially preserved as strings and additional metadata is added by default in order to preserve data governance and tracking:

current_timestamp() AS _ingest_ts,
_metadata.file_path AS _source_file,
_metadata.file_modification_time AS _source_mod_time
_rescued_data for unexpected or evolved schema fields
_corrupted_data for malformed records
Source-file metadata for lineage and troubleshooting

### Silver Layer

The Silver layer standardizes and implements strict data qaulity:

Data-type conversion
String trimming and normalization
Timestamp parsing
Duplicate removal
Null-value validation
Business-rule validation
Rejected-record isolation
Technical lineage preservation

Data having bad qaulity is managed in the qaurantine tables.

### Gold Layer

The Gold layer implements a dimensional warehouse using surrogate keys, conformed dimensions, SCD1, SCD2, and fact tables.
This layer is designed for reporting, analytical queries, and semantic models.

## Dimensional Model
The warehouse contains the following dimensions:
<img width="801" height="313" alt="image" src="https://github.com/user-attachments/assets/5749100c-4c54-4ccf-957f-9ad1f78ef79e" />


The warehouse contains the following facts:
<img width="802" height="239" alt="image" src="https://github.com/user-attachments/assets/d0368495-7edf-48af-aeb8-de88ec5a79b0" />


The fact tables are not directly joined to one another as primary analytical relationships.

## Slowly Changing Dimension Type 2

SCD Type 2 preserves the history.
For example, when a customer changes location:

customer_sk | customer_id | location_sk | effective_from | effective_to | is_current
------------|-------------|-------------|----------------|--------------|-----------
101         | CUST-001    | 501         | 2025-01-01     | 2025-06-30   | false
145         | CUST-001    | 527         | 2025-07-01     | 9999-12-31   | true

Each change creates a new surrogate-key record instead of overwriting the previous version.

During fact-table loading, the correct dimension version is selected using the business-event timestamp:

*** event_timestamp >= effective_from
AND event_timestamp < effective_to ***

This ensures that historical facts continue to reference the dimension values that were valid when the transaction occurred.

## Data Quality Framework

The project includes a reusable profiling and monitoring framework.

1. Run Profile: captures each pipeline execution.
2. Table Profile: captures dataset-level quality metrics.
3. Duplicate-Key Monitoring: stores duplicate business keys.
4. Validation Categories: business-key uniqueness, mandatory-field completeness, referential integrity, invalid timestamps, invalid numeric values, duplicate transactions, unmatched surrogate keys, rescued records, corrupted records.

Incremental processing is controlled through:

1. Streaming checkpoints
2. Delta transaction logs
3. Source-file tracking
4. Pipeline state
5. Idempotent merge transformation logic

The recommended execution sequence is:

1. Bronze ingestion
2. Silver transformation and validation
3. Data-quality profiling
4. Conformed dimensions
5. SCD Type 2 dimensions
6. Fact tables
7. Referential-integrity validation
8. Reporting and semantic models

Dependencies should be enforced through Lakeflow pipeline relationships or Databricks Workflows rather than relying on manual notebook execution.

## Key Engineering Decisions
- Parse Raw Fields as Strings to handle schema evolution.
- Raw fields are initially ingested as strings to reduce failures caused by inconsistent source schemas. Explicit type conversion is applied in the Silver layer.
- Preserve Rejected Records. Invalid records are written to rejection or quarantine tables rather than permanently removed.
- Use Surrogate Keys.
- Surrogate keys separate warehouse relationships from unstable operational business keys and support historical dimension versions.
- Orders, payments, order items, and reviews are maintained as separate fact tables because they represent different business processes and have different grains.

## Practical Experience in:
1. Lakehouse architecture
2. Incremental data ingestion
3. Streaming tables
4. Delta Lake
5. Dimensional modelling
6. Fact and dimension design
7. SCD Type 2 implementation
8. Data-quality controls
9. Surrogate-key assignment
10. Schema evolution handling
11. Pipeline monitoring
12. Data lineage
13. Production-oriented orchestration
14. Analytics-ready data preparation

## Future Enhancements

Potential future improvements include:
- CI/CD using GitHub Actions
- Automated unit and integration testing
- Centralized configuration tables
- Power BI semantic model
- Row-level security
- Data-observability dashboard
- Change Data Capture integration
- Infrastructure as Code using Terraform


