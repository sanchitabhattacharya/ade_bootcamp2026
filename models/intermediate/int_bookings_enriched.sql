with bookings as (

    select * from {{ ref('stg_bookings') }}

),

hotels as (

    select * from {{ ref('stg_hotels') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

enriched as (

    select
        b.booking_id,
        b.hotel_id,
        h.hotel_name,
        h.city                                       as hotel_city,
        h.star_rating,
        b.customer_id,
        c.first_name || ' ' || c.last_name            as customer_name,
        c.email                                       as customer_email,
        b.booking_date,
        b.check_in_date,
        b.check_out_date,
        b.num_nights,
        b.booking_amount,
        b.booking_status,
        {{ booking_status_category('b.booking_status') }} as booking_status_category

    from bookings b
    left join hotels h    on b.hotel_id = h.hotel_id
    left join customers c on b.customer_id = c.customer_id

)

select * from enriched
