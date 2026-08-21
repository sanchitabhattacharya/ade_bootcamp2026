with source as (

    select * from {{ source('lnd_sb_schema', 'customers') }}

),

renamed as (

    select
        customer_id,
        trim(first_name)            as first_name,
        trim(last_name)             as last_name,
        lower(trim(email))          as email,
        trim(country)               as country,
        signup_date

    from source

)

select * from renamed
