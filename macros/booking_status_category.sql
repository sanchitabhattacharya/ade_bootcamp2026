{#
    Reusable business logic. Instead of copy-pasting this CASE statement into
    every model that needs it (staging, intermediate, marts), we write it once
    as a macro and call {{ booking_status_category('booking_status') }} anywhere.

    If the business definition of "active" ever changes, we fix it in ONE place.
#}

{% macro booking_status_category(status_column) %}
    case
        when {{ status_column }} in ('confirmed', 'completed') then 'active'
        when {{ status_column }} = 'cancelled' then 'cancelled'
        else 'unknown'
    end
{% endmacro %}
