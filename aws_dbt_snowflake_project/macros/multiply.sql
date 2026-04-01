{% macro multiply(a, b, precision=2) %}
    round({{ a }} * {{ b }}, {{ precision }})   
{% endmacro %}