{{
    config(
        materialized='incremental',
        unique_key = ['id']
    )
}}

with recent_data as (
    select
        dt.id as symbol_id,
        dd.id as date_id,
        round(avg(tp.price), 2) as avg_price,
        current_timestamp as updated_date
    from {{ source('CryptoPricing', 'ticker_prices') }} tp
    inner join {{ ref('dim_tickers') }} dt
        on tp.symbol = dt.symbol
    inner join {{ ref('dim_date') }} dd
        on dd.full_date = extract(date from tp.timestamp)
    
    {% if is_incremental() %}
    
    where extract(date from tp.timestamp) >= current_date - {{ days_to_ingest }}
    
    {% endif %}
    
    group by 
        date_id,
        symbol_id
),

recent_data_with_id as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'symbol_id',
            'date_id',
            'avg_price'
        ]) }} as id,
        symbol_id,
        date_id,
        avg_price,
        updated_date
    from recent_data
),

final as (
    select
        id,
        symbol_id,
        date_id,
        avg_price,
        updated_date,
        coalesce(
            round(avg_price  - lag(avg_price) over (partition by symbol_id order by date_id), 2),
            0.0
        ) as price_change,
        coalesce(
            round((avg_price - lag(avg_price) over (partition by symbol_id order by date_id)) / lag(avg_price) over (partition by symbol_id order by date_id) * 100, 2),
            0.0
        ) as percentage_change
    from
        recent_data_with_id
)

select *
from final