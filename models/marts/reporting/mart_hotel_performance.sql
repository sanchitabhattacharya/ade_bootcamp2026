-- Gold layer / reporting: pre-aggregated table for dashboards.
-- Table materialization (folder default) - rebuilt in full each run since
-- it's a relatively cheap aggregation over fct_bookings.

with bookings as (

    select * from {{ ref('fct_bookings') }}

),

hotels as (

    select * from {{ ref('dim_hotels') }}

),

reviews as (

    select * from {{ ref('stg_reviews') }}

),

booking_agg as (

    select
        hotel_id,
        count(*)                                                     as total_bookings,
        sum(case when booking_status_category = 'active' then 1 else 0 end)    as active_bookings,
        sum(case when booking_status_category = 'cancelled' then 1 else 0 end) as cancelled_bookings,
        sum(booking_amount)                                          as gross_booking_value,
        sum(total_paid)                                              as total_revenue_collected,
        avg(num_nights)                                              as avg_nights_per_booking

    from bookings
    group by 1

),

review_agg as (

    select
        hotel_id,
        avg(rating)   as avg_rating,
        count(*)      as num_reviews

    from reviews
    group by 1

)

select
    h.hotel_id,
    h.hotel_name,
    h.hotel_city,
    h.hotel_country,
    h.star_rating,
    coalesce(b.total_bookings, 0)          as total_bookings,
    coalesce(b.active_bookings, 0)         as active_bookings,
    coalesce(b.cancelled_bookings, 0)      as cancelled_bookings,
    coalesce(b.gross_booking_value, 0)     as gross_booking_value,
    coalesce(b.total_revenue_collected, 0) as total_revenue_collected,
    b.avg_nights_per_booking,
    r.avg_rating,
    coalesce(r.num_reviews, 0)             as num_reviews

from hotels h
left join booking_agg b on h.hotel_id = b.hotel_id
left join review_agg r  on h.hotel_id = r.hotel_id
