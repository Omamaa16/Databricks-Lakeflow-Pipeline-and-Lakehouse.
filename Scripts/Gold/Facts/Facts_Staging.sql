----------------------------
/*orders*/
----------------------------

CREATE OR REFRESH MATERIALIZED VIEW olist_brazil.DWH_STG.fact_stg_orders
AS
SELECT o.order_id as order_id, 
       cust.customer_id as customer_id, 
       c.cust_sk as customer_sk, 
       s.status_sk as status_sk, 
       order_purchase.date_sk as order_purchase_timestamp_sk, 
       order_approved.date_sk as order_approved_timestamp_sk, 
       order_delivered_carrier.date_sk as order_delivered_carrier_timestamp_sk, 
       order_delivered_customer.date_sk as order_delivered_customer_timestamp_sk, 
       order_estimated_delivery.date_sk as order_estimated_delivery_timestamp_sk, 
       o.order_purchase_timestamp as order_purchase_timestamp, 
       o.order_approved_at as order_approved_at, 
       o.order_delivered_carrier_date as order_delivered_carrier_date, 
       o.order_delivered_customer_date as order_delivered_customer_date,
       o.order_estimated_delivery_date as order_estimated_delivery_date, 
       o.is_late_delivery as is_late_delivery, 
       current_timestamp() AS dw_ingested
FROM olist_brazil.trn.order_final o
LEFT JOIN olist_brazil.trn.customers cust
ON o.customer_id=cust.customer_id
LEFT JOIN olist_brazil.gold.dim_customers c
ON c.customer=cust.customer AND o.order_purchase_timestamp >= c.effective_from AND o.order_purchase_timestamp < COALESCE(c.effective_to, TIMESTAMP '9999-12-31')
LEFT JOIN olist_brazil.gold.dim_status s
ON o.order_status=s.order_status
LEFT JOIN olist_brazil.gold.dim_date order_purchase
ON TO_DATE(o.order_purchase_timestamp)=order_purchase.calendar_date
LEFT JOIN olist_brazil.gold.dim_date order_approved
ON TO_DATE(o.order_approved_at)=order_approved.calendar_date
LEFT JOIN olist_brazil.gold.dim_date order_delivered_carrier
ON TO_DATE(order_delivered_carrier_date)=order_delivered_carrier.calendar_date
LEFT JOIN olist_brazil.gold.dim_date order_delivered_customer
ON TO_DATE(order_delivered_customer_date)=order_delivered_customer.calendar_date
LEFT JOIN olist_brazil.gold.dim_date order_estimated_delivery
ON TO_DATE(order_estimated_delivery_date)=order_estimated_delivery.calendar_date

---------------------------------------
/*order_item*/
---------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW olist_brazil.DWH_STG.fact_stg_order_items
AS
SELECT P.PROD_SK AS prod_sk,
       OI.ORDER_ID AS order_id,
       OI.ORDER_ITEM_ID AS order_item_id,
       OI.PRODUCT_ID AS product_id,
       OI.SELLER_ID AS seller_id,
       S.seller_sk AS seller_sk,
       OI.SHIPPING_LIMIT_DATE AS shipping_limit_date,
       D.date_sk AS shipping_limit_date_sk,
       OI.PRICE AS price,
       OI.bronze_ingested AS DW_INGESTED
FROM OLIST_BRAZIL.TRN.ITEM OI
LEFT JOIN OLIST_BRAZIL.GOLD.DIM_PRODUCT P 
ON OI.PRODUCT_ID = P.PRODUCT_ID AND OI.SHIPPING_LIMIT_DATE >= P.effective_from AND OI.SHIPPING_LIMIT_DATE < COALESCE(P.effective_to, TIMESTAMP '9999-12-31')
LEFT JOIN OLIST_BRAZIL.GOLD.DIM_DATE D 
ON TO_DATE(OI.SHIPPING_LIMIT_DATE) = D.CALENDAR_DATE
LEFT JOIN OLIST_BRAZIL.GOLD.DIM_SELLER S 
ON OI.SELLER_ID = S.SELLER_ID 

---------------------------------------
/*order_review*/
---------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW olist_brazil.DWH_STG.fact_stg_order_reviews
AS
SELECT R.ORDER_ID,
       R.REVIEW_ID,
       R.REVIEW_SCORE, 
       R.REVIEW_COMMENT_TITLE,
       R.REVIEW_CREATION_DATE,
       REVIEW_CREATION.DATE_SK AS REVIEW_CREATION_DATE_SK,
       R.REVIEW_ANSWER_TIMESTAMP,
       REVIEW_ANSWER.DATE_SK AS REVIEW_ANSWER_TIMESTAMP_SK
FROM OLIST_BRAZIL.TRN.REVIEW R
LEFT JOIN olist_brazil.gold.dim_date REVIEW_CREATION
ON TO_DATE(R.REVIEW_CREATION_DATE)=REVIEW_CREATION.CALENDAR_DATE
LEFT JOIN olist_brazil.gold.dim_date REVIEW_ANSWER
ON TO_DATE(R.REVIEW_ANSWER_TIMESTAMP)=REVIEW_ANSWER.CALENDAR_DATE

------------------------------------------
/*order_payment*/
------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW olist_brazil.DWH_STG.fact_stg_order_payments
AS
SELECT OP.order_id, 
       OP.payment_sequential,
       P.payment_sk,
       OP.payment_installments,
       OP.payment_value,
       OP.bronze_ingested
FROM olist_brazil.trn.payment OP
LEFT JOIN olist_brazil.gold.dim_payment P
ON OP.payment_type=P.payment_type
