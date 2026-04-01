WITH bookings AS (
    SELECT 
        BOOKING_ID,
        BOOKING_DATE,
        BOOKING_STATUS,
        CREATED_AT
    FROM {{ ref('silver_bookings') }}
)
SELECT * FROM bookings