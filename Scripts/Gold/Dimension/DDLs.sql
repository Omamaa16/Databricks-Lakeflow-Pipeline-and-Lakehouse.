------------------------------------------------------------
/*As of now (July 2026), Databricks does not automatically
enforce referential or PK integrity; however, these have been
mentioned for readability*/
------------------------------------------------------------
  
---------------------------------------------------------------
/*dim_location*/
---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS olist_brazil.gold.dim_location
    (location_sk BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,  
    location_code STRING NOT NULL,
    city STRING NOT NULL,
    state STRING NOT NULL,
    hash_location STRING NOT NULL,
    dw_ingested TIMESTAMP NOT NULL,
    dw_updated TIMESTAMP,

    CONSTRAINT dim_location_pk
        PRIMARY KEY (location_sk),

    CONSTRAINT dim_location_business_key
        UNIQUE (location_code, city, state))
USING DELTA 
TBLPROPERTIES ('delta.columnMapping.mode' = 'name');

------------------------------------------------------------
/*dim_customer*/
------------------------------------------------------------

CREATE TABLE IF NOT EXISTS olist_brazil.gold.dim_customer
    (cust_sk BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    customer STRING NOT NULL,
    location_sk BIGINT NOT NULL,
    hash_customer STRING NOT NULL,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    is_current BOOLEAN NOT NULL,
    dw_ingested TIMESTAMP NOT NULL,
    dw_updated TIMESTAMP,

    CONSTRAINT dim_customer_pk
        PRIMARY KEY (cust_sk),

    CONSTRAINT dim_customer_version_uk
        UNIQUE (customer, effective_from),

    CONSTRAINT dim_customer_location_fk
        FOREIGN KEY (location_sk)
        REFERENCES olist_brazil.gold.dim_location (location_sk))
USING DELTA
TBLPROPERTIES
('delta.columnMapping.mode' = 'name');

-------------------------------------------------------------
/*dim_status*/
-------------------------------------------------------------

CREATE TABLE IF NOT EXISTS olist_brazil.gold.dim_status
    (status_sk BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    order_status STRING NOT NULL,
    dw_ingested TIMESTAMP NOT NULL,
    dw_updated TIMESTAMP,

    CONSTRAINT dim_status_pk
        PRIMARY KEY (status_sk),

    CONSTRAINT dim_status_business_key
        UNIQUE (order_status))
USING DELTA
TBLPROPERTIES
('delta.columnMapping.mode' = 'name');

---------------------------------------------------------------
/*dim_payment*/
---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS olist_brazil.gold.dim_payment
    (payment_sk BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
     payment_type STRING NOT NULL,
     dw_ingested TIMESTAMP NOT NULL,
     dw_updated TIMESTAMP,
        
    CONSTRAINT dim_payment_pk
        PRIMARY KEY (payment_sk),

    CONSTRAINT dim_payment_business_key
        UNIQUE (payment_type))

USING DELTA
TBLPROPERTIES
('delta.columnMapping.mode' = 'name');

-------------------------------------------------------
/*dim_product*/
-------------------------------------------------------

CREATE TABLE IF NOT EXISTS olist_brazil.gold.dim_product
    (prod_sk BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    product_id STRING NOT NULL,
    product_category_name STRING,
    product_weight_g BIGINT,
    product_size_cm INT,
    hash_product STRING NOT NULL,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    is_current BOOLEAN NOT NULL,
    dw_ingested TIMESTAMP NOT NULL,
    dw_updated TIMESTAMP,

    CONSTRAINT dim_product_pk
        PRIMARY KEY (prod_sk),

    CONSTRAINT dim_product_version_uk
        UNIQUE (product_id, effective_from))
USING DELTA
TBLPROPERTIES
('delta.columnMapping.mode' = 'name');

--------------------------------------------------------
/*dim_date*/
--------------------------------------------------------

CREATE TABLE IF NOT EXISTS olist_brazil.gold.dim_date
    (date_sk BIGINT NOT NULL,
    calendar_date DATE NOT NULL,
    day_of_month INT,
    day_of_week INT,
    day STRING,
    month_number INT,
    month STRING,
    quarter INT,
    year INT,
    is_weekend BOOLEAN,
    is_weekday BOOLEAN,
    dw_ingested TIMESTAMP NOT NULL,

    CONSTRAINT dim_date_pk
        PRIMARY KEY (date_sk),

    CONSTRAINT dim_date_calendar_date_uk
        UNIQUE (calendar_date)
)
USING DELTA
TBLPROPERTIES
('delta.columnMapping.mode' = 'name');

-------------------------------------------------------
/*dim_seller*/
-------------------------------------------------------

CREATE TABLE IF NOT EXISTS olist_brazil.gold.dim_seller
    (seller_sk BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    seller_id STRING NOT NULL,
    location_sk BIGINT NOT NULL,
    dw_modified TIMESTAMP NOT NULL,
    dw_ingested TIMESTAMP NOT NULL,

    CONSTRAINT dim_seller_pk
        PRIMARY KEY (seller_sk),

    CONSTRAINT dim_seller_business_key
        UNIQUE (seller_id),

    CONSTRAINT dim_seller_location_fk
        FOREIGN KEY (location_sk)
        REFERENCES olist_brazil.gold.dim_location (location_sk))
USING DELTA
TBLPROPERTIES
('delta.columnMapping.mode' = 'name');
