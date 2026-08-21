{#
    Shows how to WRAP a package macro (dbt_utils) in your own macro.
    Useful when several models need the same surrogate key logic but you
    don't want every model author to remember the exact column list.
#}

{% macro generate_booking_payment_key(booking_id_column, payment_id_column) %}
    {{ dbt_utils.generate_surrogate_key([booking_id_column, payment_id_column]) }}
{% endmacro %}
