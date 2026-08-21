with source as (

    select * from {{ source('lnd_sb_schema', 'reviews') }}

),

renamed as (

    select
        review_id,
        booking_id,
        hotel_id,
        customer_id,
        rating,
        review_text,
        review_date

    from source

)

select * from renamed
