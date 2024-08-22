{{
    config(
        materialized='incremental',
        unique_key = ['id']
    )
}}

with ticker_names as (
    select 
        tp.symbol as symbol,
        left(tp.symbol, length(tp.symbol) - 4) as symbol_short,
        coalesce(nm.full_name, 'N/A') as full_name,
        min(tp.timestamp) as start_timestamp
    from {{ source('CryptoPricing', 'ticker_prices') }} tp
    left join {{ ref('name_mapping') }} nm
        on left(tp.symbol, length(tp.symbol) - 4) = nm.abbreviation
    group by symbol, symbol_short, full_name
),

final as (
    select 
        {{ dbt_utils.generate_surrogate_key([
            'symbol',
            'full_name',
            'start_timestamp'
        ]) }} as id,
        symbol,
        symbol_short,
        full_name,
        start_timestamp,
        current_timestamp as updated_timestamp
    from ticker_names
)

select *
from final