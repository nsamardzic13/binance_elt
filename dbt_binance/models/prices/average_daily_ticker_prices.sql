{{
    config(
        materialized='incremental',
        partition_by = {'field': 'id', 'data_type': 'string'}
    )
}}

{% set days_to_ingest = var('days_to_ingest', 3) %}

with recent_data as (
    
    select
        extract(date from timestamp) as date,
        symbol,
        avg(price) as avg_price
    from {{ source('CryptoPricing', 'ticker_prices') }}
    
    {% if is_incremental() %}
    
    where extract(date from timestamp) >= current_date - {{ days_to_ingest }}
    
    {% endif %}
    
    group by 
        extract(date from timestamp),
        symbol
),

-- Generate unique surrogate key for recent data
recent_data_with_id as (
    select
        md5(cast(date as string) || '-' || symbol) as id,
        date,
        symbol,
        avg_price
    from recent_data
)

select *
from recent_data_with_id