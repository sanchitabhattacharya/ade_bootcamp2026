-- Gold layer: table materialization (default for marts/core, see dbt_project.yml).
-- Rebuilt in full on every run - fine for dimension tables that are small
-- and don't change often.

select
    hotel_id,
    hotel_name,
    city        as hotel_city,
    country     as hotel_country,
    star_rating,
    created_at  as hotel_created_at

from {{ ref('stg_hotels') }}
