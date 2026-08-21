-- Silver layer: aggregates payments to one row per booking.
-- Also ephemeral - purely a stepping stone toward fct_bookings.

with payments as (

    select * from {{ ref('stg_payments') }}

),

summarized as (

    select
        booking_id,
        sum(case when payment_status = 'success'  then payment_amount else 0 end) as total_paid,
        sum(case when payment_status = 'refunded' then payment_amount else 0 end) as total_refunded,
        count(*)                                                                  as num_payment_attempts,
        max(payment_date)                                                         as last_payment_date

    from payments
    group by 1

)

select * from summarized
