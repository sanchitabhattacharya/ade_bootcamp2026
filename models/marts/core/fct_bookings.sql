
{{
    config(
        materialized='incremental',
        unique_key='booking_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns'
    )
}}

with bookings_enriched as (

    select * from {{ ref('int_bookings_enriched') }}

),

payments_summary as (

    select * from {{ ref('int_payments_summary') }}

),

final as (

    select
        b.booking_id,
        b.hotel_id,
        b.customer_id,
        b.booking_date,
        b.check_in_date,
        b.check_out_date,
        b.num_nights,
        b.booking_amount,
        b.booking_status,
        b.booking_status_category,
        coalesce(p.total_paid, 0)      as total_paid,
        coalesce(p.total_refunded, 0)  as total_refunded,
        coalesce(p.num_payment_attempts, 0) as num_payment_attempts,
        {{ generate_booking_payment_key('b.booking_id', 'p.last_payment_date') }} as booking_payment_key,
        current_timestamp()             as dbt_loaded_at

    from bookings_enriched b
    left join payments_summary p on b.booking_id = p.booking_id

)

select * from final

{% if is_incremental() %}

    -- only pull in bookings that are new or have been updated since the
    -- last run - this is what makes the model actually incremental.
    where booking_date >= (select coalesce(max(booking_date), '1900-01-01') from {{ this }})

{% endif %}
