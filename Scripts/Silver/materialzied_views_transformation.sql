----------------------------------------------------------------------------
/* The scripts were originally declared in different files in the same
lakeflow pipeline, using asset bundles; however, they have been compiled 
together for the documentation

The expectations would fail the udate primarily due to the fact that the pk
is duplicated; in case of further data violations, data would be quarantined*/
-----------------------------------------------------------------------------

-------------------------------------------------------------------------------
/* Customers
 -- customer is the customer_unique_id, just written otherwise for readability*/
-------------------------------------------------------------------------------

 CREATE OR REFRESH MATERIALIZED VIEW customers_norm
(CONSTRAINT pk_null 
  EXPECT (customer_id IS NOT NULL)
  ON VIOLATION FAIL UPDATE)
AS 
SELECT trim(customer_id) as customer_id, 
       nullif(trim(customer_unique_id), '') as customer, 
       LPAD(trim(customer_zip_code_prefix), 6, 0) as customer_zipcode, 
       olist_brazil.silver.city_normalized(customer_city) as customer_city, 
       upper(trim(customer_state)) as customer_state,
       _ingest_ts as bronze_ingested_ts,
       _source_mod_time as bronze_modified_ts
FROM olist_brazil.bronze.customers;

CREATE OR REFRESH MATERIALIZED VIEW customers_clean
AS
SELECT *, CASE WHEN TRY_CAST(customer_zipcode AS INT) < 0 OR nullif(customer_zipcode, '') IS NULL THEN 'invalid_zipcode' else null
       END AS cust_clean
FROM live.customers_norm;

CREATE OR REFRESH MATERIALIZED VIEW customers_dedupe
AS
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY
            bronze_modified_ts DESC,
            bronze_ingested_ts DESC
    ) AS rn
FROM live.customers_clean;

CREATE OR REFRESH MATERIALIZED VIEW customers
AS
SELECT
    customer_id,
    customer,
    customer_zipcode,
    customer_city,
    customer_state,
    bronze_ingested_ts,
    bronze_modified_ts
FROM live.customers_dedupe
WHERE rn = 1
  AND cust_clean IS NULL;

CREATE OR REFRESH MATERIALIZED VIEW customer_quarantine
AS
SELECT *
FROM live.customers_dedupe
WHERE cust_clean IS NOT NULL
   OR rn > 1;

----------------------------------------------------------------------
/*Geolocation*/
----------------------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW loc_norm
AS
SELECT LPAD(geolocation_zip_code_prefix, 6, 0) as location_code, 
       olist_brazil.silver.city_normalized(geolocation_city) as city,
       upper(trim(geolocation_state)) as state,
       _ingest_ts as bronze_ingested,
       _source_mod_time as bronze_modified
FROM olist_brazil.bronze.geolocation;

CREATE OR REFRESH MATERIALIZED VIEW loc_dedupe
AS
SELECT *, ROW_NUMBER() OVER (PARTITION BY location_code, city, state ORDER BY bronze_modified DESC, bronze_ingested DESC) AS rn
FROM LIVE.loc_norm;

CREATE OR REFRESH MATERIALIZED VIEW loc
AS
SELECT * 
FROM live.loc_dedupe
WHERE rn=1

-------------------------------------------------------------------
/*order_items*/
-------------------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW item_norm
(CONSTRAINT pk_null 
EXPECT (order_id IS NOT NULL AND order_item_id IS NOT NULL)
ON VIOLATION FAIL UPDATE)
AS
SELECT order_id, 
       cast(order_item_id as int) AS order_item_id,
       product_id,
       seller_id,
       cast(shipping_limit_date as timestamp) as shipping_limit_date,
       cast(price as decimal(10,2)) as price,
       _ingest_ts as bronze_ingested,
       _source_mod_time as bronze_modified
FROM olist_brazil.bronze.order_items;

CREATE OR REPLACE MATERIALIZED VIEW item_clean
AS
SELECT *, CASE WHEN shipping_limit_date > current_timestamp() THEN 'invalid_shipping_date'
          WHEN price<0 THEN 'invalid_price' ELSE NULL 
          END as rejected_item
FROM live.item_norm;

CREATE OR REPLACE MATERIALIZED VIEW item_dedupe
AS
SELECT *, row_number() over (partition by order_id, order_item_id order by bronze_modified desc, bronze_ingested desc) as rn
FROM live.item_clean;

CREATE OR REPLACE MATERIALIZED VIEW item
AS
SELECT *
FROM live.item_dedupe
WHERE rn=1 AND rejected_item IS NULL;

CREATE OR REFRESH MATERIALIZED VIEW item_quarantine
AS
SELECT *
FROM live.item_dedupe
WHERE rn>1 OR rejected_item IS NOT NULL;

----------------------------------------------------------------------
/*order_payments*/
----------------------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW payment_norm
(CONSTRAINT pk_null 
EXPECT (order_id IS NOT NULL AND payment_sequential IS NOT NULL)
ON VIOLATION FAIL UPDATE)
AS
SELECT order_id, 
       cast(payment_sequential as int) AS payment_sequential,
       COALESCE(NULLIF(payment_type, ''), 'UNKNOWN') AS payment_type,
       CAST(payment_installments AS int) AS payment_installments,
       CAST(payment_value AS decimal(10,2)) AS payment_value,
       _ingest_ts as bronze_ingested,
       _source_mod_time as bronze_modified
FROM olist_brazil.bronze.order_payments;

CREATE OR REFRESH MATERIALIZED VIEW payment_dedupe
AS
SELECT *, row_number() OVER(PARTITION BY order_id, payment_sequential ORDER BY bronze_modified desc, bronze_ingested DESC) AS rn
FROM payment_norm;

CREATE OR REFRESH MATERIALIZED VIEW payment_clean
AS
SELECT *, CASE WHEN payment_installments < 0 then 'invalid_payment_installments'
          WHEN payment_value < 0 then 'invalid_payment_value'
          ELSE NULL 
          END AS payment_rejected
FROM payment_dedupe;

CREATE OR REFRESH MATERIALIZED VIEW payment
AS
SELECT *
FROM live.payment_clean
WHERE rn = 1 AND payment_rejected IS NULL;

CREATE OR REFRESH MATERIALIZED VIEW payment_quarantine
AS
SELECT *
FROM live.payment_clean
WHERE rn > 1 OR payment_rejected IS NOT NULL;

-------------------------------------------------------------------
/*order_reviews*/
-------------------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW review_norm
(CONSTRAINT pk_null 
EXPECT (order_id IS NOT NULL AND review_id IS NOT NULL)
ON VIOLATION FAIL UPDATE)
AS
SELECT order_id, 
       review_id,
       cast(review_score as int) AS review_score,
       coalesce(review_comment_title, 'NO COMMENT') AS review_comment_title,
       cast(review_creation_date as timestamp) AS review_creation_date,
       cast(review_answer_timestamp as timestamp) AS review_answer_timestamp,
       _ingest_ts as bronze_ingested,
       _source_mod_time as bronze_modified
FROM olist_brazil.bronze.order_reviews;

CREATE OR REFRESH MATERIALIZED VIEW review_clean
AS
SELECT *, CASE WHEN review_score NOT BETWEEN 1 AND 5 then 'invalid_review_score'
          WHEN review_creation_date > current_timestamp() then 'invalid_review_creation_date'
          WHEN review_answer_timestamp > current_timestamp() OR review_answer_timestamp < review_creation_date then 'invalid_review_answer_timestamp'
          ELSE NULL 
          END AS review_rejected
FROM live.review_norm;

CREATE OR REFRESH MATERIALIZED VIEW review_dedupe
AS
SELECT *, row_number() OVER(PARTITION BY order_id, review_id ORDER BY bronze_modified desc, bronze_ingested DESC) AS rn
FROM live.review_clean;

CREATE OR REFRESH MATERIALIZED VIEW review
AS
SELECT *
FROM live.review_dedupe
WHERE rn = 1 AND review_rejected IS NULL;

CREATE OR REFRESH MATERIALIZED VIEW review_quarantine
AS
SELECT *
FROM live.review_dedupe
WHERE rn > 1 OR review_rejected IS NOT NULL;

--------------------------------------------------------------------------
/*orders*/
---------------------------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW order_norm
(CONSTRAINT order_pk 
EXPECT (order_id IS NOT NULL)
ON VIOLATION FAIL UPDATE)
AS
SELECT order_id,
       customer_id,
       case when order_status is null then 'UNKNOWN' else upper(trim(order_status)) end as order_status,
       try_cast(order_purchase_timestamp as timestamp) as order_purchase_timestamp,
       try_cast(order_approved_at as timestamp) as order_approved_at,
       try_cast(order_delivered_carrier_date as timestamp) as order_delivered_carrier_date,
       try_cast(order_delivered_customer_date as timestamp) as order_delivered_customer_date,
       try_cast(order_estimated_delivery_date as timestamp) as order_estimated_delivery_date,
       _ingest_ts as bronze_ingested,
       _source_mod_time as bronze_modified
FROM OLIST_BRAZIL.bronze.orders;

CREATE OR REFRESH MATERIALIZED VIEW order_clean
AS
SELECT *, CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN TRUE ELSE FALSE END AS is_late_delivery,
       CASE WHEN order_purchase_timestamp > CURRENT_TIMESTAMP() THEN 'INVALID_PURCHASE_TIME'
       WHEN order_approved_at > CURRENT_TIMESTAMP() THEN 'INVALID_APPROVED_TIME'
       WHEN order_delivered_carrier_date > CURRENT_TIMESTAMP() THEN 'INVALID_CARRIER_TIME'
       WHEN order_delivered_customer_date > CURRENT_TIMESTAMP() THEN 'INVALID_CUSTOMER_TIME'
       WHEN order_estimated_delivery_date > CURRENT_TIMESTAMP() THEN 'INVALID_ESTIMATED_DELIVERY_TIME'
       ELSE NULL END AS rejected_order
FROM order_norm;

CREATE OR REFRESH MATERIALIZED VIEW order_deduped
AS
SELECT *, row_number() over(partition by order_id order by bronze_modified desc, bronze_ingested desc) as rn
FROM live.order_clean;

CREATE OR REFRESH MATERIALIZED VIEW order_final
AS
SELECT *
FROM live.order_deduped
WHERE rn=1 and rejected_order is null;


CREATE OR REFRESH MATERIALIZED VIEW order_quarantine
AS
SELECT *, CASE WHEN rejected_order is not null then rejected_order
          ELSE 'duplicated_id' END AS qaurantine_reason
FROM live.order_deduped
WHERE rejected_order is not null or rn>1

----------------------------------------------------------------
/*product_category_translation*/
----------------------------------------------------------------

CREATE OR REPLACE MATERIALIZED VIEW prod_cat_translation
AS
SELECT DISTINCT UPPER(TRIM(product_category_name)) AS product_category_name,
       UPPER(TRIM(product_category_name_english)) AS product_english
FROM olist_brazil.bronze.product_category_name_translation

------------------------------------------------------------------
/*products*/
------------------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW product_norm
(CONSTRAINT pk_null 
EXPECT (product_id IS NOT NULL)
ON VIOLATION FAIL UPDATE)
AS
SELECT product_id, 
       upper(trim(product_category_name)) as product_category_name,
       cast(product_weight_g as bigint) AS product_weight_g,
       (cast(product_length_cm as int) * cast(product_height_cm as int) * cast(product_width_cm as int)) AS product_size_cm,
       _ingest_ts as bronze_ingested,
       _source_mod_time as bronze_modified
FROM olist_brazil.bronze.products;

CREATE OR REFRESH MATERIALIZED VIEW product_clean
AS
SELECT *, CASE WHEN product_weight_g < 0 then 'invalid_prod_weight'
          WHEN product_size_cm < 0 then 'invalid_prod_size'
          ELSE NULL 
          END AS product_rejected
FROM live.product_norm;

CREATE OR REFRESH MATERIALIZED VIEW product_dedupe
AS
SELECT *, row_number() OVER(PARTITION BY product_id ORDER BY bronze_modified desc, bronze_ingested DESC) AS rn
FROM live.product_clean;

CREATE OR REFRESH MATERIALIZED VIEW product
AS
SELECT *
FROM live.product_dedupe
WHERE rn = 1 AND product_rejected IS NULL;

CREATE OR REFRESH MATERIALIZED VIEW product_quarantine
AS
SELECT *
FROM live.product_dedupe
WHERE rn > 1 OR product_rejected IS NOT NULL;

----------------------------------------------------------------------
/*sellers*/
----------------------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW seller_norm
(CONSTRAINT pk_null 
EXPECT (seller_id IS NOT NULL)
ON VIOLATION FAIL UPDATE)
AS
SELECT seller_id, 
       LPAD(seller_zip_code_prefix, 6, 0) as seller_zipcode,
       olist_brazil.silver.city_normalized(seller_city) AS seller_city,
       trim(upper(seller_state)) AS seller_state,
       _ingest_ts as bronze_ingested,
       _source_mod_time as bronze_modified
FROM olist_brazil.bronze.sellers;

CREATE OR REFRESH MATERIALIZED VIEW seller_dedupe
AS
SELECT *, row_number() OVER(PARTITION BY seller_id ORDER BY bronze_modified desc, bronze_ingested DESC) AS rn
FROM live.seller_norm;

CREATE OR REFRESH MATERIALIZED VIEW seller
AS
SELECT *
FROM live.seller_dedupe
WHERE rn = 1;

CREATE OR REFRESH MATERIALIZED VIEW seller_quarantine
AS
SELECT *
FROM live.seller_dedupe
WHERE rn > 1;


