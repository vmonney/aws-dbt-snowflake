{{ config(alias='dim_date') }}

WITH bounds AS (
    SELECT
        COALESCE(DATEADD(year, -1, MIN(CAST(CREATED_AT AS DATE))), TO_DATE('2010-01-01')) AS min_date,
        COALESCE(DATEADD(year, 1, MAX(CAST(CREATED_AT AS DATE))), TO_DATE('2035-12-31')) AS max_date
    FROM {{ ref('silver_bookings') }}
),
series AS (
    SELECT
        DATEADD(
            day,
            SEQ4(),
            (SELECT min_date FROM bounds)
        ) AS date_day
    FROM TABLE(GENERATOR(ROWCOUNT => 20000))
),
filtered_dates AS (
    SELECT date_day
    FROM series
    WHERE date_day <= (SELECT max_date FROM bounds)
)
SELECT
    TO_NUMBER(TO_CHAR(date_day, 'YYYYMMDD')) AS date_key,
    date_day,
    EXTRACT(year FROM date_day) AS year_number,
    EXTRACT(quarter FROM date_day) AS quarter_number,
    CONCAT('Q', EXTRACT(quarter FROM date_day)) AS quarter_label,
    EXTRACT(month FROM date_day) AS month_number,
    TO_CHAR(date_day, 'MMMM') AS month_name,
    TO_CHAR(date_day, 'YYYY-MM') AS year_month,
    EXTRACT(day FROM date_day) AS day_of_month,
    DAYOFWEEKISO(date_day) AS day_of_week_iso,
    TO_CHAR(date_day, 'DY') AS day_name_short,
    IFF(DAYOFWEEKISO(date_day) IN (6, 7), TRUE, FALSE) AS is_weekend
FROM filtered_dates
