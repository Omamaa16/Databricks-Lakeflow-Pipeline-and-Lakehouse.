--------------------------------------------------
/*gelocation*/
--------------------------------------------------

MERGE INTO olist_brazil.gold.dim_location t
USING (SELECT * FROM olist_brazil.dwh_stg.dim_stg_loc) s
ON t.location_code=s.location_code and t.state=s.state
WHEN MATCHED and coalesce(t.hash_loc, '') <> coalesce(s.hash_loc, '')
THEN UPDATE 
SET t.hash_loc=s.hash_loc,
    t.city=s.city,
    t.dw_updated=current_timestamp()
WHEN NOT MATCHED THEN 
INSERT (location_code, city, state, hash_loc, dw_ingested, dw_updated)
VALUES (
    s.location_code,
    s.city,
    s.state,
    s.hash_loc,
    dw_ingested,
    current_timestamp())

-------------------------------------------------------
  /*customer*/
-------------------------------------------------------

MERGE INTO olist_brazil.gold.dim_customers t
USING (SELECT * FROM olist_brazil.dwh_stg.dim_stg_cust) s
ON t.customer=s.customer and is_current=TRUE  
WHEN MATCHED AND NOT (t.location_sk <=> s.location_sk) 
THEN UPDATE 
SET t.effective_to = current_timestamp(),
    t.is_current = FALSE,
    t.dw_updated=current_timestamp();

INSERT INTO olist_brazil.gold.dim_customers(
    customer,
    location_sk,
    effective_from,
    effective_to,
    is_current,
    dw_ingested,
    dw_updated
) SELECT 
    s.customer,
    s.location_sk,
    current_timestamp(),
    null,
    TRUE,
    s.dw_ingested,
    current_timestamp()
FROM olist_brazil.dwh_stg.dim_stg_cust s
LEFT JOIN olist_brazil.gold.dim_customers t
ON s.customer = t.customer AND t.is_current = TRUE
WHERE t.customer IS NULL

-------------------------------------------------------
/*status*/
-------------------------------------------------------

MERGE INTO olist_brazil.gold.dim_status t
USING (SELECT DISTINCT order_status FROM olist_brazil.silver.order_final) s
ON t.order_status=s.order_status
WHEN NOT MATCHED 
THEN INSERT (
    order_status,
    dw_ingested,
    dw_updated
) VALUES (
    s.order_status,
    s.bronze_ingested,
    current_timestamp())

----------------------------------------------------
/*payment*/
----------------------------------------------------

MERGE INTO olist_brazil.gold.dim_payment t
USING (SELECT DISTINCT payment_type, bronze_ingested FROM olist_brazil.silver.payment) s
ON t.payment_type=s.payment_type
WHEN NOT MATCHED 
THEN INSERT (
    payment_type,
    dw_ingested,
    dw_updated
) VALUES (
    s.payment_type,
    s.bronze_ingested,
    current_timestamp()
)

--------------------------------------------------
/*product*/
--------------------------------------------------

MERGE INTO olist_brazil.gold.dim_product t
USING (SELECT * FROM olist_brazil.dwh_stg.dim_stg_prod) s
on coalesce(t.product_id, '') = coalesce(s.product_id, '') and t.is_current=TRUE
WHEN MATCHED AND t.hash_prod <> s.hash_prod 
THEN UPDATE 
SET effective_to = current_timestamp(),
    is_current = FALSE,
    dw_updated=current_timestamp();

INSERT INTO olist_brazil.gold.dim_product (
    product_id,
    product_category_name,
    product_weight_g,
    product_size_cm,
    hash_prod,
    effective_from,
    effective_to,
    is_current,
    dw_ingested,
    dw_updated
) SELECT 
    s.product_id,
    s.product_category_name,
    s.product_weight_g,
    s.product_size_cm,
    s.hash_prod,
    current_timestamp(),
    null,
    TRUE,
    s.bronze_ingested,
    current_timestamp()
FROM olist_brazil.dwh_stg.dim_stg_prod s       
LEFT JOIN olist_brazil.gold.dim_product t
ON s.product_id = t.product_id AND t.is_current = TRUE
WHERE t.product_id IS NULL

------------------------------------------------
/*date*/
------------------------------------------------

INSERT OVERWRITE olist_brazil.gold.dim_date
WITH dates as (SELECT EXPLODE(SEQUENCE(
            TO_DATE('2010-01-01'),
            TO_DATE('2035-12-31'),
            INTERVAL 1 DAY
)) AS calendar_date),

date_data AS
(SELECT CAST(DATE_FORMAT(calendar_date, 'yyyyMMdd') AS INT) AS date_sk,
        calendar_date,
        DAY(calendar_date) AS day_of_month,
        DAYOFWEEK(calendar_date) AS day_of_week,
        DAYNAME(calendar_date) AS day,
        MONTH(calendar_date) AS month_number,
        DATE_FORMAT(calendar_date, 'MMMM') AS month,
        QUARTER(calendar_date) AS quarter,
        YEAR(calendar_date) AS year,
        CASE WHEN WEEKDAY(calendar_date) IN (5, 6) THEN TRUE ELSE FALSE END AS is_weekend,
        CASE WHEN WEEKDAY(calendar_date) NOT IN (5, 6) THEN TRUE ELSE FALSE END AS is_weekday,
        CURRENT_TIMESTAMP() AS dw_ingested 
FROM dates)

-----------------------------------------------
/*seller*/
-----------------------------------------------

MERGE INTO olist_brazil.gold.dim_seller t
USING (SELECT * FROM olist_brazil.dwh_stg.dim_stg_sellers) s
ON t.seller_id=s.seller_id
WHEN MATCHED THEN UPDATE 
    SET t.location_sk=s.location_sk, t.dw_modified=current_timestamp()
WHEN NOT MATCHED THEN INSERT 
    (seller_id, 
    location_sk, 
    dw_ingested) 
VALUES (s.seller_id, 
        s.location_sk, 
        current_timestamp())
