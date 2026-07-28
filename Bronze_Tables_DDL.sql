-- Profiling Tables Creation

=========================================================
--BRONZE: CUSTOMERS

CREATE OR REFRESH STREAMING TABLE customers
TBLPROPERTIES (
  'delta.columnMapping.mode' = 'name'
)
AS
SELECT
  customer_id,
  customer_unique_id,
  customer_zip_code_prefix,
  customer_city,
  customer_state,

  _rescued_data,
  _corrupted_data,

  current_timestamp() AS _ingest_ts,
  _metadata.file_path AS _source_file,
  _metadata.file_name AS _source_file_name,
  _metadata.file_modification_time AS _source_mod_time

FROM STREAM read_files(
  "/Volumes/olist_brazil/land/olist_raw/customers/",
  format => "csv",
  header => true,
  quote => '"',
  multiline => true,
  sep => ",",
  escape => '"',

  mode => "PERMISSIVE",
  columnNameOfCorruptRecord => "_corrupted_data",

  schema => "customer_id STRING, customer_unique_id STRING, customer_zip_code_prefix STRING, customer_city STRING, customer_state STRING, _corrupted_data STRING",

  schemaEvolutionMode => "rescue",
  rescuedDataColumn => "_rescued_data"
);

-- BRONZE: GEOLOCATION

CREATE OR REFRESH STREAMING TABLE geolocation
TBLPROPERTIES (
  'delta.columnMapping.mode' = 'name'
)
AS
SELECT
  geolocation_zip_code_prefix,
  geolocation_lat,
  geolocation_lng,
  geolocation_city,
  geolocation_state,

  _rescued_data,
  _corrupted_data,

  current_timestamp() AS _ingest_ts,
  _metadata.file_path AS _source_file,
  _metadata.file_name AS _source_file_name,
  _metadata.file_modification_time AS _source_mod_time

FROM STREAM read_files(
  "/Volumes/olist_brazil/land/olist_raw/geolocation/",
  format => "csv",
  header => true,
  quote => '"',
  multiline => true,
  sep => ",",
  escape => '"',

  mode => "PERMISSIVE",
  columnNameOfCorruptRecord => "_corrupted_data",

  schema => "geolocation_zip_code_prefix STRING, geolocation_lat STRING, geolocation_lng STRING, geolocation_city STRING, geolocation_state STRING, _corrupted_data STRING",

  schemaEvolutionMode => "rescue",
  rescuedDataColumn => "_rescued_data"
);

-- BRONZE: ORDERS


CREATE OR REFRESH STREAMING TABLE orders
TBLPROPERTIES (
  'delta.columnMapping.mode' = 'name'
)
AS
SELECT
  order_id,
  customer_id,
  order_status,
  order_purchase_timestamp,
  order_approved_at,
  order_delivered_carrier_date,
  order_delivered_customer_date,
  order_estimated_delivery_date,

  _rescued_data,
  _corrupted_data,

  current_timestamp() AS _ingest_ts,
  _metadata.file_path AS _source_file,
  _metadata.file_name AS _source_file_name,
  _metadata.file_modification_time AS _source_mod_time

FROM STREAM read_files(
  "/Volumes/olist_brazil/land/olist_raw/orders/",
  format => "csv",
  header => true,
  quote => '"',
  multiline => true,
  sep => ",",
  escape => '"',

  mode => "PERMISSIVE",
  columnNameOfCorruptRecord => "_corrupted_data",

  schema => "order_id STRING, customer_id STRING, order_status STRING, order_purchase_timestamp STRING, order_approved_at STRING, order_delivered_carrier_date STRING, order_delivered_customer_date STRING, order_estimated_delivery_date STRING, _corrupted_data STRING",

  schemaEvolutionMode => "rescue",
  rescuedDataColumn => "_rescued_data"
);


-- BRONZE: ORDER ITEMS


CREATE OR REFRESH STREAMING TABLE order_items
TBLPROPERTIES (
  'delta.columnMapping.mode' = 'name'
)
AS
SELECT
  order_id,
  order_item_id,
  product_id,
  seller_id,
  shipping_limit_date,
  price,
  freight_value,

  _rescued_data,
  _corrupted_data,

  current_timestamp() AS _ingest_ts,
  _metadata.file_path AS _source_file,
  _metadata.file_name AS _source_file_name,
  _metadata.file_modification_time AS _source_mod_time

FROM STREAM read_files(
  "/Volumes/olist_brazil/land/olist_raw/order_items/",
  format => "csv",
  header => true,
  quote => '"',
  multiline => true,
  sep => ",",
  escape => '"',

  mode => "PERMISSIVE",
  columnNameOfCorruptRecord => "_corrupted_data",

  schema => "order_id STRING, order_item_id STRING, product_id STRING, seller_id STRING, shipping_limit_date STRING, price STRING, freight_value STRING, _corrupted_data STRING",

  schemaEvolutionMode => "rescue",
  rescuedDataColumn => "_rescued_data"
);


-- BRONZE: ORDER PAYMENTS


CREATE OR REFRESH STREAMING TABLE order_payments
TBLPROPERTIES (
  'delta.columnMapping.mode' = 'name'
)
AS
SELECT
  order_id,
  payment_sequential,
  payment_type,
  payment_installments,
  payment_value,

  _rescued_data,
  _corrupted_data,

  current_timestamp() AS _ingest_ts,
  _metadata.file_path AS _source_file,
  _metadata.file_name AS _source_file_name,
  _metadata.file_modification_time AS _source_mod_time

FROM STREAM read_files(
  "/Volumes/olist_brazil/land/olist_raw/order_payments/",
  format => "csv",
  header => true,
  quote => '"',
  multiline => true,
  sep => ",",
  escape => '"',

  mode => "PERMISSIVE",
  columnNameOfCorruptRecord => "_corrupted_data",

  schema => "order_id STRING, payment_sequential STRING, payment_type STRING, payment_installments STRING, payment_value STRING, _corrupted_data STRING",

  schemaEvolutionMode => "rescue",
  rescuedDataColumn => "_rescued_data"
);

-- BRONZE: ORDER REVIEWS

CREATE OR REFRESH STREAMING TABLE order_reviews
TBLPROPERTIES (
  'delta.columnMapping.mode' = 'name'
)
AS
SELECT
  review_id,
  order_id,
  review_score,
  review_comment_title,
  review_comment_message,
  review_creation_date,
  review_answer_timestamp,

  _rescued_data,
  _corrupted_data,

  current_timestamp() AS _ingest_ts,
  _metadata.file_path AS _source_file,
  _metadata.file_name AS _source_file_name,
  _metadata.file_modification_time AS _source_mod_time

FROM STREAM read_files(
  "/Volumes/olist_brazil/land/olist_raw/order_reviews/",
  format => "csv",
  header => true,
  quote => '"',
  multiline => true,
  sep => ",",
  escape => '"',

  mode => "PERMISSIVE",
  columnNameOfCorruptRecord => "_corrupted_data",

  schema => "review_id STRING, order_id STRING, review_score STRING, review_comment_title STRING, review_comment_message STRING, review_creation_date STRING, review_answer_timestamp STRING, _corrupted_data STRING",

  schemaEvolutionMode => "rescue",
  rescuedDataColumn => "_rescued_data"
);



-- BRONZE: PRODUCTS

CREATE OR REFRESH STREAMING TABLE products
TBLPROPERTIES (
  'delta.columnMapping.mode' = 'name'
)
AS
SELECT
  product_id,
  product_category_name,
  product_name_lenght,
  product_description_lenght,
  product_photos_qty,
  product_weight_g,
  product_length_cm,
  product_height_cm,
  product_width_cm,

  _rescued_data,
  _corrupted_data,

  current_timestamp() AS _ingest_ts,
  _metadata.file_path AS _source_file,
  _metadata.file_name AS _source_file_name,
  _metadata.file_modification_time AS _source_mod_time

FROM STREAM read_files(
  "/Volumes/olist_brazil/land/olist_raw/products/",
  format => "csv",
  header => true,
  quote => '"',
  multiline => true,
  sep => ",",
  escape => '"',

  mode => "PERMISSIVE",
  columnNameOfCorruptRecord => "_corrupted_data",

  schema => "product_id STRING, product_category_name STRING, product_name_lenght STRING, product_description_lenght STRING, product_photos_qty STRING, product_weight_g STRING, product_length_cm STRING, product_height_cm STRING, product_width_cm STRING, _corrupted_data STRING",

  schemaEvolutionMode => "rescue",
  rescuedDataColumn => "_rescued_data"
);


-- BRONZE: SELLERS

CREATE OR REFRESH STREAMING TABLE sellers
TBLPROPERTIES (
  'delta.columnMapping.mode' = 'name'
)
AS
SELECT
  seller_id,
  seller_zip_code_prefix,
  seller_city,
  seller_state,

  _rescued_data,
  _corrupted_data,

  current_timestamp() AS _ingest_ts,
  _metadata.file_path AS _source_file,
  _metadata.file_name AS _source_file_name,
  _metadata.file_modification_time AS _source_mod_time

FROM STREAM read_files(
  "/Volumes/olist_brazil/land/olist_raw/sellers/",
  format => "csv",
  header => true,
  quote => '"',
  multiline => true,
  sep => ",",
  escape => '"',

  mode => "PERMISSIVE",
  columnNameOfCorruptRecord => "_corrupted_data",

  schema => "seller_id STRING, seller_zip_code_prefix STRING, seller_city STRING, seller_state STRING, _corrupted_data STRING",

  schemaEvolutionMode => "rescue",
  rescuedDataColumn => "_rescued_data"
);


-- BRONZE: PRODUCT CATEGORY NAME TRANSLATION

CREATE OR REFRESH STREAMING TABLE product_category_name_translation
TBLPROPERTIES (
  'delta.columnMapping.mode' = 'name'
)
AS
SELECT
  product_category_name,
  product_category_name_english,

  _rescued_data,
  _corrupted_data,

  current_timestamp() AS _ingest_ts,
  _metadata.file_path AS _source_file,
  _metadata.file_name AS _source_file_name,
  _metadata.file_modification_time AS _source_mod_time

FROM STREAM read_files(
  "/Volumes/olist_brazil/land/olist_raw/product_category_name_translation/",
  format => "csv",
  header => true,
  quote => '"',
  multiline => true,
  sep => ",",
  escape => '"',

  mode => "PERMISSIVE",
  columnNameOfCorruptRecord => "_corrupted_data",

  schema => "product_category_name STRING, product_category_name_english STRING, _corrupted_data STRING",

  schemaEvolutionMode => "rescue",
  rescuedDataColumn => "_rescued_data"
);
