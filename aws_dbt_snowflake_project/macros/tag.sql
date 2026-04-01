{% macro tag(column_name) %}
    CASE
        WHEN TRY_TO_NUMBER({{ column_name }})::INT < 100 THEN 'low'
        WHEN TRY_TO_NUMBER({{ column_name }})::INT < 200 THEN 'medium'
        ELSE 'high'
    END
{% endmacro %}