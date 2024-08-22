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
        avg(a.free) + avg(a.locked) as quantity
    from {{ source('CryptoPricing', 'account_snaphsot') }} a
    inner join {{ ref('dim_tickers') }} dt
        on a.asset = dt.symbol_short
    inner join {{ ref('dim_date') }} dd
        on dd.full_date = extract(date from a.timestamp)
    
    where (a.free > 0.0 or a.locked > 0.0)

    {% if is_incremental() %}
    
    and extract(date from a.timestamp) >= current_date - {{ var('days_to_ingest') }}
    
    {% endif %}

    group by 
        symbol_id,
        date_id

),

change as (
    select 
        symbol_id,
        date_id,
        quantity,
        coalesce(
            round(quantity  - lag(quantity) over (partition by symbol_id order by date_id), 2),
            0.0
        ) as quantity_change,
        coalesce(
            round((quantity - lag(quantity) over (partition by symbol_id  order by date_id)) / lag(quantity) over (partition by symbol_id  order by date_id) * 100, 2),
            0.0
        ) as percentage_change
    from current_portfolio
),

final as (
    select 
        {{ dbt_utils.generate_surrogate_key([
            'symbol_id',
            'date_id',
            'quantity'
        ]) }} as id,
        symbol_id,
        date_id,
        quantity,
        quantity_change,
        percentage_change,
        current_timestamp as updated_timestamp
    from change
)

select *
from final