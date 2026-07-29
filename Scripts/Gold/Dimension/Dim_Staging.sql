-----------------------------------------
/*customers

the latest customer according to the 
latest order placed has been chosen*/
-----------------------------------------

CREATE OR REPLACE MATERIALIZED VIEW olist_brazil.DWH_STG.dim_stg_cust
AS
WITH cust_rnk AS (SELECT customer,
       customer_zipcode, 
       customer_city,
       customer_state,
       bronze_ingested_ts as dw_ingested,
       bronze_modified_ts as dw_updated,
       row_number() over (partition by customer order by o.order_purchase_timestamp DESC, bronze_modified_ts DESC, c.bronze_ingested_ts DESC) rn
FROM olist_brazil.silver.customers c     
LEFT JOIN olist_brazil.silver.order_final o
on c.customer_id = o.customer_id)

SELECT c.customer, 
       l.location_sk,
       c.dw_ingested,
       c.dw_updated
FROM cust_rnk c
LEFT JOIN olist_brazil.gold.dim_location l
ON c.customer_zipcode=l.location_code AND c.customer_state=l.state
WHERE rn=1;
       
------------------------------------------------------------------
/*geolocation*

the location came from three tables: geolocation, customers, and
sellers. The priority has been given to the zipcodes present in 
geoloation, then customers, and then sellers*/
------------------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW olist_brazil.DWH_STG.dim_stg_loc 
AS 
WITH total_code_state as (SELECT location_code, city, state, 3 as src, bronze_ingested, bronze_modified
                          FROM olist_brazil.silver.loc
                          UNION ALL 
                          SELECT customer_zipcode, customer_city, customer_state, 2 as src, bronze_ingested_ts, bronze_modified_ts
                          FROM olist_brazil.silver.customers
                          UNION ALL 
                          SELECT seller_zipcode, seller_city, seller_state, 1 as src, bronze_ingested, bronze_modified
                          FROM olist_brazil.silver.seller)

SELECT location_code, 
       city,
       state, 
       olist_brazil.gold.generate_hash(city) as hash_loc,
       bronze_ingested as dw_ingested
FROM (
    SELECT location_code, state, city, bronze_ingested, row_number() over (partition by location_code, state order by src desc, bronze_ingested desc) as rn
from total_code_state
) 
where rn=1;

------------------------------------------------------------------
/*products*/
------------------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW olist_brazil.DWH_STG.dim_stg_prod 
AS
 SELECT product_id,
        product_category_name,
        product_weight_g,
        product_size_cm,
        olist_brazil.gold.generate_hash(product_category_name, CAST(product_weight_g AS STRING), CAST(product_size_cm AS STRING)) as hash_prod,
        bronze_ingested
FROM olist_brazil.silver.product;

------------------------------------------------------------------
/*sellers*/
------------------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW olist_brazil.DWH_STG.dim_stg_sellers 
AS
SELECT s.seller_id, l.location_sk, s.bronze_ingested
FROM olist_brazil.silver.seller s
LEFT JOIN olist_brazil.gold.dim_location l
ON s.seller_zipcode=l.location_code AND s.seller_state=l.state 

