--------------------------------------
/*orders*/
--------------------------------------

MERGE INTO olist_brazil.gold.fact_orders t
USING (SELECT * FROM olist_brazil.dwh_stg.fact_stg_orders) s
ON t.order_id = s.order_id
WHEN MATCHED THEN UPDATE 
    SET t.customer_id=s.customer_id,
    t.customer_sk=s.customer_sk,
    t.status_sk=s.status_sk,
    t.order_purchase_timestamp_sk=s.order_purchase_timestamp_sk,
    t.order_approved_at_sk=s.order_approved_timestamp_sk,
    t.order_delivered_carrier_date_sk=s.order_delivered_carrier_timestamp_sk,
    t.order_delivered_customer_date_sk=s.order_delivered_customer_timestamp_sk,
    t.order_estimated_delivery_date_sk=s.order_estimated_delivery_timestamp_sk,
    t.order_purchase_timestamp=s.order_purchase_timestamp,
    t.order_approved_at=s.order_approved_at,
    t.order_delivered_carrier_date=s.order_delivered_carrier_date,
    t.order_delivered_customer_date=s.order_delivered_customer_date,
    t.order_estimated_delivery_date=s.order_estimated_delivery_date,
    t.is_late_delivery=s.is_late_delivery,
    t.dw_ingested=current_timestamp()
WHEN NOT MATCHED 
THEN INSERT (
    order_id,
    customer_id,
    customer_sk,
    status_sk,
    order_purchase_timestamp_sk,
    order_approved_at_sk,
    order_delivered_carrier_date_sk,
    order_delivered_customer_date_sk,
    order_estimated_delivery_date_sk,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    is_late_delivery,
    dw_ingested
)
VALUES (s.order_id,
    s.customer_id,
    s.customer_sk,
    s.status_sk,
    s.order_purchase_timestamp_sk,
    s.order_approved_timestamp_sk,
    s.order_delivered_carrier_timestamp_sk,
    s.order_delivered_customer_timestamp_sk,
    s.order_estimated_delivery_timestamp_sk,
    s.order_purchase_timestamp,
    s.order_approved_at,
    s.order_delivered_carrier_date,
    s.order_delivered_customer_date,
    s.order_estimated_delivery_date,
    s.is_late_delivery,
    current_timestamp())

---------------------------------------
/*order_items*/
---------------------------------------

MERGE INTO olist_brazil.gold.fact_order_items t
USING (SELECT * FROM olist_brazil.dwh_stg.fact_stg_order_items) s
ON t.order_id = s.order_id AND t.order_item_id = s.order_item_id
WHEN MATCHED THEN UPDATE 
    SET t.prod_sk=s.prod_sk,
    t.order_id=s.order_id,
    t.order_item_id=s.order_item_id,
    t.product_id=s.product_id,
    t.seller_id=s.seller_id,
    t.shipping_limit_date=s.shipping_limit_date,
    t.shipping_limit_date_sk=s.shipping_limit_date_sk,
    t.seller_sk=s.seller_sk,
    t.price=s.price,
    t.DW_INGESTED=s.DW_INGESTED
WHEN NOT MATCHED 
THEN INSERT (
    prod_sk,
    order_id,
    order_item_id,
    product_id,
    seller_id,
    seller_sk,
    shipping_limit_date,
    shipping_limit_date_sk,
    price,
    DW_INGESTED
)
VALUES (
    s.prod_sk,
    s.order_id,
    s.order_item_id,
    s.product_id,
    s.seller_id,
    s.seller_sk,
    s.shipping_limit_date,
    s.shipping_limit_date_sk,
    s.price,
    current_timestamp())

--------------------------------------------
/*order_payments*/
--------------------------------------------

MERGE INTO olist_brazil.gold.fact_order_payments t
USING (SELECT * FROM olist_brazil.dwh_stg.fact_stg_order_payments) s
ON t.order_id = s.order_id AND t.payment_sequential = s.payment_sequential
WHEN MATCHED THEN UPDATE 
    SET t.payment_sk=s.payment_sk,
    t.payment_installments=s.payment_installments,
    t.payment_value=s.payment_value,
    t.bronze_ingested=current_timestamp()
WHEN NOT MATCHED 
THEN INSERT (
    order_id,
    payment_sequential,
    payment_sk,
    payment_installments,
    payment_value,
    bronze_ingested
)
VALUES (
    s.order_id,
    s.payment_sequential,
    s.payment_sk,
    s.payment_installments,
    s.payment_value,
    current_timestamp()
)

-----------------------------------------------
/*order_review*/
-----------------------------------------------

MERGE INTO olist_brazil.gold.fact_order_review t
USING (SELECT * FROM olist_brazil.dwh_stg.fact_stg_order_reviews) s
ON t.order_id = s.order_id AND t.review_id = s.review_id
WHEN MATCHED THEN UPDATE 
    SET t.review_score=s.review_score,
    t.review_comment_title=s.review_comment_title,
    t.review_creation_date=s.review_creation_date,
    t.review_creation_date_sk=s.review_creation_date_sk,
    t.review_answer_timestamp=s.review_answer_timestamp,
    t.review_answer_timestamp_sk=s.review_answer_timestamp_sk,
    t.bronze_ingested=current_timestamp()
WHEN NOT MATCHED 
THEN INSERT (
    order_id, 
    review_id,
    review_score,
    review_comment_title,
    review_creation_date,
    review_creation_date_sk,
    review_answer_timestamp,
    review_answer_timestamp_sk,
    bronze_ingested
)
VALUES (
    s.order_id, 
    s.review_id,
    s.review_score,
    s.review_comment_title,
    s.review_creation_date,
    s.review_creation_date_sk,
    s.review_answer_timestamp,
    s.review_answer_timestamp_sk,
    current_timestamp()
)
