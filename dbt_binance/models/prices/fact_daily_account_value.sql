{{
    config(
        materialized='incremental',
        unique_key = ['id']
    )
}}

with current_portfolio as (
    select
        dt.id as symbol_id,
        dd.id as date_id,
        a.free + a.locked as quantity
    from {{ source('CryptoPricing', 'account_snaphsot') }} a
    inner join {{ ref('dim_tickers') }} dt
        on a.asset = dt.symbol_short
    inner join {{ ref('dim_date') }} dd
        on dd.full_date = extract(date from a.timestamp)

    where 
        (a.free > 0.0 or a.locked > 0.0)
    
    {% if is_incremental() %}
    
    and extract(date from a.timestamp) >= current_date - {{ var('days_to_ingest') }}
    
    {% endif %}

),

ticker_portflio_values as (
    select 
        f.date_id,
        avg_price * c.quantity as usd_value
    from {{ ref('fact_average_daily_ticker_prices') }} f
    inner join current_portfolio c
        on f.symbol_id = c.symbol_id
        and f.date_id = c.date_id
),

total_value as (
    select
        t.date_id,
        round(sum(t.usd_value), 2) as wallet_value
    from ticker_portflio_values t
    group by t.date_id
),

total_value_change as (
    select
        date_id,
        wallet_value,
        coalesce(
            round(wallet_value  - lag(wallet_value) over (order by date_id), 2),
            0.0
        ) as price_change,
        coalesce(
            round((wallet_value - lag(wallet_value) over (order by date_id)) / lag(wallet_value) over (order by date_id) * 100, 2),
            0.0
        ) as percentage_change
    from total_value
),

final as (
    select 
        {{ dbt_utils.generate_surrogate_key([
            'date_id',
            'wallet_value'
        ]) }} as id,
        date_id,
        wallet_value,
        price_change,
        percentage_change
    from total_value_change
)

select *
from final