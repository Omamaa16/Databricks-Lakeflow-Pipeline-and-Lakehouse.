%sql
CREATE FUNCTION IF NOT EXISTS olist_brazil.silver.city_normalized (
    city STRING)
    RETURNS STRING
RETURN CASE WHEN city IS NULL THEN NULL
            ELSE regexp_replace(translate(lower(trim(city)),'áàâãäéèêëíìîïóòôõöúùûüçñ', 'aaaaaeeeeiiiiooooouuuucn'), '[^a-z0-9]', '')
        END;
