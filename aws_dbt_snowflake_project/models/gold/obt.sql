{{ config(alias='obt') }}

{% set model_configs = [
    {
        "model": "silver_bookings",
        "alias": "b",
        "columns": [
            "BOOKING_ID",
            "LISTING_ID",
            "BOOKING_DATE",
            "TOTAL_BOOKING_AMOUNT",
            "BOOKING_STATUS",
            "CREATED_AT AS BOOKING_CREATED_AT"
        ]
    },
    {
        "model": "silver_listings",
        "alias": "l",
        "columns": [
            "HOST_ID",
            "PROPERTY_TYPE",
            "ROOM_TYPE",
            "CITY",
            "COUNTRY",
            "ACCOMMODATES",
            "BEDROOMS",
            "BATHROOMS",
            "PRICE_PER_NIGHT",
            "PRICE_PER_NIGHT_TAG",
            "CREATED_AT AS LISTING_CREATED_AT"
        ],
        "join_condition": "b.LISTING_ID = l.LISTING_ID"
    },
    {
        "model": "silver_hosts",
        "alias": "h",
        "columns": [
            "HOST_NAME",
            "HOST_SINCE",
            "IS_SUPERHOST",
            "RESPONSE_RATE",
            "RESPONSE_RATE_TAG",
            "CREATED_AT AS HOST_CREATED_AT"
        ],
        "join_condition": "l.HOST_ID = h.HOST_ID"
    }
] %}

SELECT
    {% set ns = namespace(first_col=true) %}
    {% for model_config in model_configs %}
        {% for column in model_config.columns %}
            {% if not ns.first_col %},{% endif %}
    {{ model_config.alias }}.{{ column }}
            {% set ns.first_col = false %}
        {% endfor %}
    {% endfor %}
FROM {{ ref(model_configs[0].model) }} AS {{ model_configs[0].alias }}
{% for model_config in model_configs[1:] %}
LEFT JOIN {{ ref(model_config.model) }} AS {{ model_config.alias }}
    ON {{ model_config.join_condition }}
{% endfor %}