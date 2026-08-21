select
    customer_id,
    first_name,
    last_name,
    first_name || ' ' || last_name as customer_name,
    email,
    country as customer_country,
    signup_date

from {{ ref('stg_customers') }}
