{{
    config(
        materialized='incremental',
        unique_key = ['id']
    )
}}

{% set days_to_ingest = var('days_to_ingest', 3) %}

with recent_data as (
    
    select
        extract(date from timestamp) as date,
        symbol,
        round(avg(price), 2) as avg_price,
        current_timestamp as updated_date
    from {{ source('CryptoPricing', 'ticker_prices') }}
    
    -- limit to the last x days
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
        {{ dbt_utils.generate_surrogate_key([
            'date',
            'symbol'
        ]) }} as id,
        date,
        symbol,
        avg_price,
        updated_date
    from recent_data
)

select *
from recent_data_with_id