with source as (

    select * from {{ source('lnd_sb_schema', 'bookings') }}

),

renamed as (

    select
        booking_id,
        hotel_id,
        customer_id,
        booking_date,
        check_in_date,
        check_out_date,
        num_nights,
        booking_amount,
        lower(trim(booking_status)) as booking_status,
        created_at,
        updated_at

    from source

)

select * from renamed
