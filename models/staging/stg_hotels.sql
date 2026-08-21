-- Bronze layer: 1:1 with source, just renaming/casting/cleaning.
-- No joins, no business logic here - that belongs in intermediate/marts.

with source as (

    select * from {{ source('lnd_sb_schema', 'hotels') }}

),

renamed as (

    select
        hotel_id,
        trim(hotel_name)      as hotel_name,
        trim(city)            as city,
        trim(country)         as country,
        star_rating,
        created_at

    from source

)

select * from renamed
