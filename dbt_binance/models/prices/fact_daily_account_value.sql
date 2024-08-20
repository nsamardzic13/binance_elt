{{
    config(
        materialized='incremental',
        unique_key = ['id']
    )
}}

with current_portfolio as (
    select
        dt.id as symbol_id,
        extract(date from a.timestamp) as date,
        a.free + a.locked as quantity
    from {{ source('CryptoPricing', 'account_snaphsot') }} a
    inner join {{ ref('dim_tickers') }} dt
        on a.asset = dt.symbol_short
    where 
        (a.free > 0.0 or a.locked > 0.0)
    {% if is_incremental() %}
    
    and extract(date from a.timestamp) >= current_date - {{ days_to_ingest }}
    
    {% endif %}

),

ticker_portflio_values as (
    select 
        f.symbol_id,
        f.date,
        avg_price * c.quantity as usd_value
    from {{ ref('fact_average_daily_ticker_prices') }} f
    inner join current_portfolio c
        on f.symbol_id = c.symbol_id
        and f.date = c.date
),

total_value as (
    select
        t.date,
        round(sum(t.usd_value), 2) as wallet_value
    from ticker_portflio_values t
    group by t.date
),

total_value_change as (
    select
        date,
        wallet_value,
        coalesce(
            round(wallet_value  - lag(wallet_value) over (order by date), 2),
            0.0
        ) as price_change,
        coalesce(
            round((wallet_value - lag(wallet_value) over (order by date)) / lag(wallet_value) over (order by date) * 100, 2),
            0.0
        ) as percentage_change
    from total_value
),

final as (
    select 
        {{ dbt_utils.generate_surrogate_key([
            'date',
            'wallet_value'
        ]) }} as id,
        date,
        wallet_value,
        price_change,
        percentage_change
    from total_value_change
)

select *
from final