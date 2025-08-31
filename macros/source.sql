{% macro _original_source() %}
    {{ return(builtins.source(*varargs, **kwargs)) }}
{% endmacro %}


{# Override the source macro #}
{% macro source(source_name, table_name) %}
    {% if is_unit_test() %}
        {{ return(builtins.source(source_name, table_name)) }}

    {% elif var("ci_row_limit", 0) > 0 %}
        {# 1. Try to get source node from graph to access meta #}
        {% set source_node = graph.sources[source_name][table_name] if source_name in graph.sources and table_name in graph.sources[source_name] else none %}

        {% if source_node is not none and source_node.meta.get('external_location') is not none %}
            {% set external_location = source_node.meta.get('external_location') %}
            {{ log("CI MODE: Using external_location with LIMIT " ~ var("ci_row_limit"), info=true) }}
            {{ return("(" ~ external_location ~ " limit " ~ var("ci_row_limit") ~ ") as " ~ source_name ~ "_" ~ table_name) }}

        {% else %}
            {# Fallback to the relation (normal db.schema.table) #}
            {% set rel = builtins.source(source_name, table_name) %}
            {{ log("CI MODE: Using " ~ rel ~ " with LIMIT " ~ var("ci_row_limit"), info=true) }}
            {{ return("(select * from " ~ rel ~ " limit " ~ var("ci_row_limit") ~ ") as " ~ source_name ~ "_" ~ table_name) }}
        {% endif %}

    {% else %}
        {{ return(_original_source(source_name, table_name)) }}
    {% endif %}
{% endmacro %}





{% macro is_unit_test() %}
    {% set in_unit_test = false %}

    {# Try to access model variable safely #}
    {% if model is defined %}
        {# Check if we’re in a test context by examining the model or node properties #}
        {% set model_str = model | string %}
        {% if '/unit_test/' in model_str %}
            {% set in_unit_test = true %}
        {% endif %}
    {% endif %}

    {{ return(in_unit_test) }}
{% endmacro %}
