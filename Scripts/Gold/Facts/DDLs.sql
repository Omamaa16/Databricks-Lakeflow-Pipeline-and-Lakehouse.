------------------------------------------
/*fact_orders*/
------------------------------------------

CREATE TABLE IF NOT EXISTS olist_brazil.gold.fact_orders
    (fact_order_sk BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    order_id STRING NOT NULL,
    customer_id STRING NOT NULL,
    customer_sk BIGINT NOT NULL,
    status_sk BIGINT NOT NULL,
    order_purchase_timestamp_sk BIGINT NOT NULL,
    order_approved_at_sk BIGINT,
    order_delivered_carrier_date_sk BIGINT,
    order_delivered_customer_date_sk BIGINT,
    order_estimated_delivery_date_sk BIGINT,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    is_late_delivery BOOLEAN,
    dw_ingested TIMESTAMP NOT NULL,

    CONSTRAINT fact_orders_pk
        PRIMARY KEY (fact_order_sk),

    CONSTRAINT fact_orders_order_id_uk
        UNIQUE (order_id),

    CONSTRAINT fact_orders_customer_fk
        FOREIGN KEY (customer_sk)
        REFERENCES olist_brazil.gold.dim_customers (cust_sk),

    CONSTRAINT fact_orders_status_fk
        FOREIGN KEY (status_sk)
        REFERENCES olist_brazil.gold.dim_status (status_sk),

    CONSTRAINT fact_orders_purchase_date_fk
        FOREIGN KEY (order_purchase_timestamp_sk)
        REFERENCES olist_brazil.gold.dim_date (date_sk),

    CONSTRAINT fact_orders_approved_date_fk
        FOREIGN KEY (order_approved_at_sk)
        REFERENCES olist_brazil.gold.dim_date (date_sk),

    CONSTRAINT fact_orders_carrier_date_fk
        FOREIGN KEY (order_delivered_carrier_date_sk)
        REFERENCES olist_brazil.gold.dim_date (date_sk),

    CONSTRAINT fact_orders_delivery_date_fk
        FOREIGN KEY (order_delivered_customer_date_sk)
        REFERENCES olist_brazil.gold.dim_date (date_sk),

    CONSTRAINT fact_orders_estimated_date_fk
        FOREIGN KEY (order_estimated_delivery_date_sk)
        REFERENCES olist_brazil.gold.dim_date (date_sk))
USING DELTA
TBLPROPERTIES
('delta.columnMapping.mode' = 'name');

---------------------------------------------------
/*fact_order_items*/
---------------------------------------------------

CREATE TABLE IF NOT EXISTS olist_brazil.gold.fact_order_items
    (fact_order_item_sk BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    prod_sk BIGINT NOT NULL,
    order_id STRING NOT NULL,
    order_item_id INT NOT NULL,
    product_id STRING NOT NULL,
    seller_sk BIGINT NOT NULL,
    seller_id STRING NOT NULL,
    shipping_limit_date TIMESTAMP,
    shipping_limit_date_sk BIGINT,
    price DECIMAL(18,2) NOT NULL,
    dw_ingested TIMESTAMP NOT NULL,

    CONSTRAINT fact_order_items_pk
        PRIMARY KEY (fact_order_item_sk),

    CONSTRAINT fact_order_items_business_key_uk
        UNIQUE (order_id, order_item_id),

    CONSTRAINT fact_order_items_product_fk
        FOREIGN KEY (prod_sk)
        REFERENCES olist_brazil.gold.dim_product (prod_sk),

    CONSTRAINT fact_order_items_seller_fk
        FOREIGN KEY (seller_sk)
        REFERENCES olist_brazil.gold.dim_seller (seller_sk),

    CONSTRAINT fact_order_items_shipping_date_fk
        FOREIGN KEY (shipping_limit_date_sk)
        REFERENCES olist_brazil.gold.dim_date (date_sk),

    CONSTRAINT fact_order_items_item_id_chk
        CHECK (order_item_id > 0),

    CONSTRAINT fact_order_items_price_chk
        CHECK (price >= 0)
)
USING DELTA
TBLPROPERTIES
('delta.columnMapping.mode' = 'name');

--------------------------------------------------
/*fact_order_payments*/
--------------------------------------------------

CREATE TABLE IF NOT EXISTS olist_brazil.gold.fact_order_payments
    (fact_payment_sk BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    order_id STRING NOT NULL,
    payment_sequential INT NOT NULL,
    payment_sk BIGINT NOT NULL,
    payment_installments INT NOT NULL,
    payment_value DECIMAL(18,2) NOT NULL,
    bronze_ingested TIMESTAMP NOT NULL,

    CONSTRAINT fact_order_payments_pk
        PRIMARY KEY (fact_payment_sk),

    CONSTRAINT fact_order_payments_business_key_uk
        UNIQUE (order_id, payment_sequential),

    CONSTRAINT fact_order_payments_payment_fk
        FOREIGN KEY (payment_sk)
        REFERENCES olist_brazil.gold.dim_payment (payment_sk),

    CONSTRAINT fact_order_payments_sequence_chk
        CHECK (payment_sequential > 0),

    CONSTRAINT fact_order_payments_installments_chk
        CHECK (payment_installments >= 0),

    CONSTRAINT fact_order_payments_value_chk
        CHECK (payment_value >= 0))
USING DELTA
TBLPROPERTIES
('delta.columnMapping.mode' = 'name');

-----------------------------------------------
/*fact_order_review*/
-----------------------------------------------

CREATE TABLE IF NOT EXISTS olist_brazil.gold.fact_order_review
    (fact_review_sk BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    order_id STRING NOT NULL,
    review_id STRING NOT NULL,
    review_score INT NOT NULL,
    review_comment_title STRING,
    review_creation_date TIMESTAMP NOT NULL,
    review_creation_date_sk BIGINT NOT NULL,
    review_answer_timestamp TIMESTAMP,
    review_answer_timestamp_sk BIGINT,
    bronze_ingested TIMESTAMP NOT NULL,

    CONSTRAINT fact_order_review_pk
        PRIMARY KEY (fact_review_sk),

    CONSTRAINT fact_order_review_business_key_uk
        UNIQUE (review_id),

    CONSTRAINT fact_order_review_creation_date_fk
        FOREIGN KEY (review_creation_date_sk)
        REFERENCES olist_brazil.gold.dim_date (date_sk),

    CONSTRAINT fact_order_review_answer_date_fk
        FOREIGN KEY (review_answer_timestamp_sk)
        REFERENCES olist_brazil.gold.dim_date (date_sk),

    CONSTRAINT fact_order_review_timestamp_chk
        CHECK (review_answer_timestamp IS NULL OR review_creation_date <= review_answer_timestamp))
USING DELTA
TBLPROPERTIES
('delta.columnMapping.mode' = 'name');
