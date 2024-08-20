{{
    config(
        materialized='incremental',
        unique_key = ['id']
    )
}}

{% set days_to_ingest = var('days_to_ingest', 3) %}

with recent_data as (
    
    select
        extract(date from tp.timestamp) as date,
        dt.id as symbol_id,
        round(avg(tp.price), 2) as avg_price,
        current_timestamp as updated_date
    from {{ source('CryptoPricing', 'ticker_prices') }} tp
    inner join {{ ref('dim_tickers') }} dt
        on tp.symbol = dt.symbol
    
    -- limit to the last x days
    {% if is_incremental() %}
    
    where extract(date from tp.timestamp) >= current_date - {{ days_to_ingest }}
    
    {% endif %}
    
    group by 
        date,
        symbol_id
),

-- Generate unique surrogate key for recent data
recent_data_with_id as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'date',
            'symbol_id'
        ]) }} as id,
        symbol_id,
        avg_price,
        date,
        updated_date
    from recent_data
),

price_changes as (
    select
        id,
        symbol_id,
        avg_price,
        date,
        updated_date,
        coalesce(
            round(avg_price  - lag(avg_price) over (partition by symbol_id order by date), 2),
            0.0
        ) as price_change,
        coalesce(
            round((avg_price - lag(avg_price) over (partition by symbol_id order by date)) / lag(avg_price) over (partition by symbol_id order by date) * 100, 2),
            0.0
        ) as percentage_change
    from
        recent_data_with_id
)

select *
from price_changes