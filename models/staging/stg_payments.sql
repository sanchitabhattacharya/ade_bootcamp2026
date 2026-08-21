with source as (

    select * from {{ source('lnd_sb_schema', 'payments') }}

),

renamed as (

    select
        payment_id,
        booking_id,
        payment_date,
        payment_amount,
        lower(trim(payment_method)) as payment_method,
        lower(trim(payment_status)) as payment_status

    from source

)

select * from renamed
