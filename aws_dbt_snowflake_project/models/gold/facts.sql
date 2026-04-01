{{ config(alias='fact_bookings') }}

WITH base_bookings AS (
    SELECT
        BOOKING_ID,
        LISTING_ID,
        CAST(BOOKING_DATE AS DATE) AS booking_date,
        CAST(CREATED_AT AS TIMESTAMP_NTZ) AS booking_created_at,
        TOTAL_BOOKING_AMOUNT,
        BOOKING_STATUS
    FROM {{ ref('silver_bookings') }}
),
listing_host_fallback AS (
    SELECT
        LISTING_ID,
        HOST_ID
    FROM {{ ref('silver_listings') }}
),
fact_enriched AS (
    SELECT
        b.BOOKING_ID,
        b.LISTING_ID,
        COALESCE(l.HOST_ID, lf.HOST_ID) AS HOST_ID,
        TO_NUMBER(TO_CHAR(CAST(b.booking_created_at AS DATE), 'YYYYMMDD')) AS booking_created_date_key,
        b.booking_date,
        b.booking_created_at,
        b.TOTAL_BOOKING_AMOUNT AS gross_booking_value,
        b.BOOKING_STATUS AS booking_status,
        IFF(UPPER(b.BOOKING_STATUS) = 'CANCELLED', TRUE, FALSE) AS is_cancelled,
        IFF(UPPER(b.BOOKING_STATUS) = 'CANCELLED', 1, 0) AS cancelled_booking_count,
        IFF(UPPER(b.BOOKING_STATUS) = 'CANCELLED', 0, 1) AS completed_booking_count,
        IFF(UPPER(b.BOOKING_STATUS) = 'CANCELLED', 0, b.TOTAL_BOOKING_AMOUNT) AS gross_booking_value_excl_cancelled,
        l.dbt_scd_id AS listing_scd_id,
        h.dbt_scd_id AS host_scd_id
    FROM base_bookings AS b
    LEFT JOIN {{ ref('dim_listings') }} AS l
        ON b.LISTING_ID = l.LISTING_ID
        AND b.booking_created_at >= COALESCE(l.dbt_valid_from, TO_TIMESTAMP_NTZ('1900-01-01'))
        AND b.booking_created_at < COALESCE(l.dbt_valid_to, TO_TIMESTAMP_NTZ('9999-12-31'))
    LEFT JOIN listing_host_fallback AS lf
        ON b.LISTING_ID = lf.LISTING_ID
    LEFT JOIN {{ ref('dim_hosts') }} AS h
        ON COALESCE(l.HOST_ID, lf.HOST_ID) = h.HOST_ID
        AND b.booking_created_at >= COALESCE(h.dbt_valid_from, TO_TIMESTAMP_NTZ('1900-01-01'))
        AND b.booking_created_at < COALESCE(h.dbt_valid_to, TO_TIMESTAMP_NTZ('9999-12-31'))
)
SELECT
    f.BOOKING_ID,
    f.LISTING_ID,
    f.HOST_ID,
    f.listing_scd_id,
    f.host_scd_id,
    d.date_key AS booking_created_date_key,
    d.date_day AS booking_created_date,
    f.booking_date,
    f.booking_created_at,
    f.gross_booking_value,
    f.gross_booking_value_excl_cancelled,
    f.booking_status,
    f.is_cancelled,
    f.cancelled_booking_count,
    f.completed_booking_count
FROM fact_enriched AS f
LEFT JOIN {{ ref('dim_date') }} AS d
    ON f.booking_created_date_key = d.date_key
