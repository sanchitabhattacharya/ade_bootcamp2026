with bookings as (

    select * from {{ ref('fct_bookings') }}

),

customers as (

    select * from {{ ref('dim_customers') }}

),

customer_agg as (

    select
        customer_id,
        count(*)                                                                as total_bookings,
        sum(case when booking_status_category = 'active' then total_paid else 0 end) as lifetime_value,
        min(booking_date)                                                       as first_booking_date,
        max(booking_date)                                                       as most_recent_booking_date

    from bookings
    group by 1

)

select
    c.customer_id,
    c.customer_name,
    c.email,
    c.customer_country,
    coalesce(a.total_bookings, 0)     as total_bookings,
    coalesce(a.lifetime_value, 0)     as lifetime_value,
    a.first_booking_date,
    a.most_recent_booking_date

from customers c
left join customer_agg a on c.customer_id = a.customer_id
