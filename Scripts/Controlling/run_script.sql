BEGIN
    DECLARE v_run_id       STRING    DEFAULT uuid();
    DECLARE v_started_at   TIMESTAMP DEFAULT current_timestamp();
    DECLARE v_retention_ts TIMESTAMP DEFAULT current_timestamp() - INTERVAL 90 DAYS;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    failure_handler: BEGIN

        UPDATE olist_brazil.control.run_profile
        SET
            completed_at = current_timestamp(),
            run_status   = 'FAILED',
            remarks      = 'Bronze profiling failed. Review the Databricks job error.',
            updated_at   = current_timestamp()
        WHERE run_id = v_run_id;

        RESIGNAL;

    END failure_handler;

    INSERT INTO olist_brazil.control.run_profile (
        run_id,
        layer_name,
        scope_name,
        started_at,
        completed_at,
        run_status,
        remarks,
        created_at,
        updated_at
    )
    VALUES (
        v_run_id,
        'BRONZE',
        'olist_brazil.bronze',
        v_started_at,
        NULL,
        'RUNNING',
        'Bronze ingestion-quality and table profiling started',
        v_started_at,
        v_started_at);

-- for the purpose of sustaining the rentention time till 90 days.

    DELETE FROM olist_brazil.control.ingestion_quality
    WHERE measured_at < v_retention_ts;


    DELETE FROM olist_brazil.control.table_profile
    WHERE profiled_at < v_retention_ts;


    DELETE FROM olist_brazil.control.duplicate_keys
    WHERE profiled_at < v_retention_ts;


    DELETE FROM olist_brazil.control.run_profile
    WHERE started_at < v_retention_ts
      AND run_id <> v_run_id;

    INSERT INTO olist_brazil.control.ingestion_quality (
        run_id,
        layer_name,
        table_catalog,
        table_schema,
        table_name,
        rescued_record_count,
        corrupted_record_count,
        source_file_count,
        measured_at)

    SELECT
        v_run_id,
        'BRONZE',
        'olist_brazil',
        'bronze',
        'customers',
        COUNT_IF(_rescued_data IS NOT NULL),
        COUNT_IF(_corrupted_data IS NOT NULL),
        COUNT(DISTINCT _source_file),
        v_started_at
    FROM olist_brazil.bronze.customers

    UNION ALL

    SELECT
        v_run_id,
        'BRONZE',
        'olist_brazil',
        'bronze',
        'geolocation',
        COUNT_IF(_rescued_data IS NOT NULL),
        COUNT_IF(_corrupted_data IS NOT NULL),
        COUNT(DISTINCT _source_file),
        v_started_at
    FROM olist_brazil.bronze.geolocation

    UNION ALL

    SELECT
        v_run_id,
        'BRONZE',
        'olist_brazil',
        'bronze',
        'orders',
        COUNT_IF(_rescued_data IS NOT NULL),
        COUNT_IF(_corrupted_data IS NOT NULL),
        COUNT(DISTINCT _source_file),
        v_started_at
    FROM olist_brazil.bronze.orders

    UNION ALL

    SELECT
        v_run_id,
        'BRONZE',
        'olist_brazil',
        'bronze',
        'order_items',
        COUNT_IF(_rescued_data IS NOT NULL),
        COUNT_IF(_corrupted_data IS NOT NULL),
        COUNT(DISTINCT _source_file),
        v_started_at
    FROM olist_brazil.bronze.order_items

    UNION ALL

    SELECT
        v_run_id,
        'BRONZE',
        'olist_brazil',
        'bronze',
        'order_payments',
        COUNT_IF(_rescued_data IS NOT NULL),
        COUNT_IF(_corrupted_data IS NOT NULL),
        COUNT(DISTINCT _source_file),
        v_started_at
    FROM olist_brazil.bronze.order_payments

    UNION ALL

    SELECT
        v_run_id,
        'BRONZE',
        'olist_brazil',
        'bronze',
        'order_reviews',
        COUNT_IF(_rescued_data IS NOT NULL),
        COUNT_IF(_corrupted_data IS NOT NULL),
        COUNT(DISTINCT _source_file),
        v_started_at
    FROM olist_brazil.bronze.order_reviews

    UNION ALL

    SELECT
        v_run_id,
        'BRONZE',
        'olist_brazil',
        'bronze',
        'products',
        COUNT_IF(_rescued_data IS NOT NULL),
        COUNT_IF(_corrupted_data IS NOT NULL),
        COUNT(DISTINCT _source_file),
        v_started_at
    FROM olist_brazil.bronze.products

    UNION ALL

    SELECT
        v_run_id,
        'BRONZE',
        'olist_brazil',
        'bronze',
        'sellers',
        COUNT_IF(_rescued_data IS NOT NULL),
        COUNT_IF(_corrupted_data IS NOT NULL),
        COUNT(DISTINCT _source_file),
        v_started_at
    FROM olist_brazil.bronze.sellers

    UNION ALL

    SELECT
        v_run_id,
        'BRONZE',
        'olist_brazil',
        'bronze',
        'product_category_name_translation',
        COUNT_IF(_rescued_data IS NOT NULL),
        COUNT_IF(_corrupted_data IS NOT NULL),
        COUNT(DISTINCT _source_file),
        v_started_at
    FROM olist_brazil.bronze.product_category_name_translation;

    INSERT INTO olist_brazil.control.table_profile (
        run_id,
        layer_name,
        table_catalog,
        table_schema,
        table_name,
        table_row_count,
        table_column_count,
        valid_business_key_count,
        distinct_business_key_count,
        duplicate_business_key_count,
        null_business_key_count,
        profiled_at
    )

    WITH profiles AS (

        SELECT
            'customers' AS table_name,
            COUNT(*) AS table_row_count,
            COUNT_IF(
                NULLIF(TRIM(customer_id), '') IS NOT NULL
            ) AS valid_business_key_count,
            COUNT(
                DISTINCT NULLIF(TRIM(customer_id), '')
            ) AS distinct_business_key_count,
            COUNT_IF(
                NULLIF(TRIM(customer_id), '') IS NULL
            ) AS null_business_key_count
        FROM olist_brazil.bronze.customers
        UNION ALL


        /* --------------------------------------------------------------------
         Geolocation
         Composite business key:
         zip code + city + latitude + longitude + state
         --------------------------------------------------------------------*/

        SELECT
            'geolocation',

            COUNT(*),

            COUNT_IF(
                NULLIF(TRIM(geolocation_zip_code_prefix), '') IS NOT NULL
                AND NULLIF(TRIM(geolocation_city), '') IS NOT NULL
                AND NULLIF(TRIM(geolocation_lat), '') IS NOT NULL
                AND NULLIF(TRIM(geolocation_lng), '') IS NOT NULL
                AND NULLIF(TRIM(geolocation_state), '') IS NOT NULL
            ),

            COUNT(
                DISTINCT CASE
                    WHEN NULLIF(TRIM(geolocation_zip_code_prefix), '') IS NOT NULL
                     AND NULLIF(TRIM(geolocation_city), '') IS NOT NULL
                     AND NULLIF(TRIM(geolocation_lat), '') IS NOT NULL
                     AND NULLIF(TRIM(geolocation_lng), '') IS NOT NULL
                     AND NULLIF(TRIM(geolocation_state), '') IS NOT NULL

                    THEN STRUCT(
                        TRIM(geolocation_zip_code_prefix),
                        TRIM(geolocation_city),
                        TRIM(geolocation_lat),
                        TRIM(geolocation_lng),
                        TRIM(geolocation_state)
                    )
                END
            ),

            COUNT_IF(
                NULLIF(TRIM(geolocation_zip_code_prefix), '') IS NULL
                OR NULLIF(TRIM(geolocation_city), '') IS NULL
                OR NULLIF(TRIM(geolocation_lat), '') IS NULL
                OR NULLIF(TRIM(geolocation_lng), '') IS NULL
                OR NULLIF(TRIM(geolocation_state), '') IS NULL
            )

        FROM olist_brazil.bronze.geolocation


        UNION ALL


        /* --------------------------------------------------------------------
         Orders
         Business key: order_id
         --------------------------------------------------------------------*/

        SELECT
            'orders',

            COUNT(*),

            COUNT_IF(
                NULLIF(TRIM(order_id), '') IS NOT NULL
            ),

            COUNT(
                DISTINCT NULLIF(TRIM(order_id), '')
            ),

            COUNT_IF(
                NULLIF(TRIM(order_id), '') IS NULL
            )

        FROM olist_brazil.bronze.orders


        UNION ALL


        /* --------------------------------------------------------------------
         Order Items
         Composite business key: order_id + order_item_id
         --------------------------------------------------------------------*/

        SELECT
            'order_items',

            COUNT(*),

            COUNT_IF(
                NULLIF(TRIM(order_id), '') IS NOT NULL
                AND NULLIF(TRIM(order_item_id), '') IS NOT NULL
            ),

            COUNT(
                DISTINCT CASE
                    WHEN NULLIF(TRIM(order_id), '') IS NOT NULL
                     AND NULLIF(TRIM(order_item_id), '') IS NOT NULL

                    THEN STRUCT(
                        TRIM(order_id),
                        TRIM(order_item_id)
                    )
                END
            ),

            COUNT_IF(
                NULLIF(TRIM(order_id), '') IS NULL
                OR NULLIF(TRIM(order_item_id), '') IS NULL
            )

        FROM olist_brazil.bronze.order_items


        UNION ALL


        /* --------------------------------------------------------------------
         Order Payments
         Composite business key: order_id + payment_sequential
         --------------------------------------------------------------------*/

        SELECT
            'order_payments',

            COUNT(*),

            COUNT_IF(
                NULLIF(TRIM(order_id), '') IS NOT NULL
                AND NULLIF(TRIM(payment_sequential), '') IS NOT NULL
            ),

            COUNT(
                DISTINCT CASE
                    WHEN NULLIF(TRIM(order_id), '') IS NOT NULL
                     AND NULLIF(TRIM(payment_sequential), '') IS NOT NULL

                    THEN STRUCT(
                        TRIM(order_id),
                        TRIM(payment_sequential)
                    )
                END
            ),

            COUNT_IF(
                NULLIF(TRIM(order_id), '') IS NULL
                OR NULLIF(TRIM(payment_sequential), '') IS NULL
            )

        FROM olist_brazil.bronze.order_payments


        UNION ALL


        /*--------------------------------------------------------------------
         Order Reviews
         Composite business key: order_id + review_id
         --------------------------------------------------------------------*/

        SELECT
            'order_reviews',

            COUNT(*),

            COUNT_IF(
                NULLIF(TRIM(order_id), '') IS NOT NULL
                AND NULLIF(TRIM(review_id), '') IS NOT NULL
            ),

            COUNT(
                DISTINCT CASE
                    WHEN NULLIF(TRIM(order_id), '') IS NOT NULL
                     AND NULLIF(TRIM(review_id), '') IS NOT NULL

                    THEN STRUCT(
                        TRIM(order_id),
                        TRIM(review_id)
                    )
                END
            ),

            COUNT_IF(
                NULLIF(TRIM(order_id), '') IS NULL
                OR NULLIF(TRIM(review_id), '') IS NULL
            )

        FROM olist_brazil.bronze.order_reviews


        UNION ALL


        /*--------------------------------------------------------------------
         Products
         Business key: product_id
        --------------------------------------------------------------------*/

        SELECT
            'products',

            COUNT(*),

            COUNT_IF(
                NULLIF(TRIM(product_id), '') IS NOT NULL
            ),

            COUNT(
                DISTINCT NULLIF(TRIM(product_id), '')
            ),

            COUNT_IF(
                NULLIF(TRIM(product_id), '') IS NULL
            )

        FROM olist_brazil.bronze.products


        UNION ALL


        /*--------------------------------------------------------------------
         Sellers
         Business key: seller_id
         --------------------------------------------------------------------*/

        SELECT
            'sellers',

            COUNT(*),

            COUNT_IF(
                NULLIF(TRIM(seller_id), '') IS NOT NULL
            ),

            COUNT(
                DISTINCT NULLIF(TRIM(seller_id), '')
            ),

            COUNT_IF(
                NULLIF(TRIM(seller_id), '') IS NULL
            )

        FROM olist_brazil.bronze.sellers


        UNION ALL


        /*--------------------------------------------------------------------
         Product Category Translation
         Business key: product_category_name
         --------------------------------------------------------------------*/

        SELECT
            'product_category_name_translation',

            COUNT(*),

            COUNT_IF(
                NULLIF(TRIM(product_category_name), '') IS NOT NULL
            ),

            COUNT(
                DISTINCT NULLIF(TRIM(product_category_name), '')
            ),

            COUNT_IF(
                NULLIF(TRIM(product_category_name), '') IS NULL
            )

        FROM olist_brazil.bronze.product_category_name_translation

    ),

    column_counts AS (

        SELECT
            table_name,
            COUNT(*) AS table_column_count

        FROM olist_brazil.information_schema.columns

        WHERE table_schema = 'bronze'

          AND table_name IN (
              'customers',
              'geolocation',
              'orders',
              'order_items',
              'order_payments',
              'order_reviews',
              'products',
              'sellers',
              'product_category_name_translation'
          )

        GROUP BY table_name

    )


    SELECT
        v_run_id AS run_id,
        'BRONZE' AS layer_name,
        'olist_brazil' AS table_catalog,
        'bronze' AS table_schema,
        p.table_name,
        p.table_row_count,
        COALESCE(c.table_column_count, 0) AS table_column_count,
        p.valid_business_key_count,
        p.distinct_business_key_count,

        p.valid_business_key_count
            - p.distinct_business_key_count
            AS duplicate_business_key_count,

        p.null_business_key_count,
        v_started_at AS profiled_at

    FROM profiles p

    LEFT JOIN column_counts c
        ON p.table_name = c.table_name;


    /*------------------------------------------------------------------------
    -- 5. Capture duplicate business-key details
    ---------------------------------------------------------------------------/*

    INSERT INTO olist_brazil.control.duplicate_keys (
        run_id,
        profiled_at,
        layer_name,
        table_catalog,
        table_schema,
        table_name,
        key_columns,
        key_value,
        duplicate_count
    )

    WITH duplicate_details AS (


        /* --------------------------------------------------------------------
         Geolocation duplicates
         --------------------------------------------------------------------*/

        SELECT
            'geolocation',

            'geolocation_zip_code_prefix, geolocation_city, geolocation_lat, geolocation_lng, geolocation_state',

            TO_JSON(
                NAMED_STRUCT(
                    'geolocation_zip_code_prefix',
                    TRIM(geolocation_zip_code_prefix),

                    'geolocation_city',
                    TRIM(geolocation_city),

                    'geolocation_lat',
                    TRIM(geolocation_lat),

                    'geolocation_lng',
                    TRIM(geolocation_lng),

                    'geolocation_state',
                    TRIM(geolocation_state)
                )
            ),

            COUNT(*)

        FROM olist_brazil.bronze.geolocation

        WHERE NULLIF(TRIM(geolocation_zip_code_prefix), '') IS NOT NULL
          AND NULLIF(TRIM(geolocation_city), '') IS NOT NULL
          AND NULLIF(TRIM(geolocation_lat), '') IS NOT NULL
          AND NULLIF(TRIM(geolocation_lng), '') IS NOT NULL
          AND NULLIF(TRIM(geolocation_state), '') IS NOT NULL

        GROUP BY
            TRIM(geolocation_zip_code_prefix),
            TRIM(geolocation_city),
            TRIM(geolocation_lat),
            TRIM(geolocation_lng),
            TRIM(geolocation_state)

        HAVING COUNT(*) > 1


    /* ------------------------------------------------------------------------
     6. Mark as completed
     ------------------------------------------------------------------------*/

    UPDATE olist_brazil.control.run_profile

    SET
        completed_at = current_timestamp(),
        run_status   = 'COMPLETED',
        remarks      = 'Bronze ingestion-quality and table profiling completed successfully',
        updated_at   = current_timestamp()

    WHERE run_id = v_run_id;


 
