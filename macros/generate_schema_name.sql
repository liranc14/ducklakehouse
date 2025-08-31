{% macro generate_schema_name(custom_schema_name, node) %}
    {# Check for CI mode from vars #}
    {% if var('ci_row_limit', 0) > 0 %}
        {{ return("ci") }}

    {% else %}
        {# If a model explicitly defines a schema, use it as-is #}
        {% if custom_schema_name is not none %}
            {{ return(custom_schema_name) }}
        {% else %}
            {{ return(target.schema) }}
        {% endif %}
    {% endif %}
{% endmacro %}
