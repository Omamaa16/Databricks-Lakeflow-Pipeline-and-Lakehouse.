%sql
CREATE FUNCTION IF NOT EXISTS olist_brazil.gold.generate_hash(
    col1 STRING, col2 STRING DEFAULT '', col3 STRING DEFAULT '')
RETURNS STRING
RETURN sha2(
    concat_ws('|', COALESCE(TRIM(col1), ''), COALESCE(TRIM(col2), ''), COALESCE(TRIM(col3), '')), 256);
