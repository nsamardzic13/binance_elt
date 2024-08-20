{{
    config(
        materialized='incremental',
        unique_key = ['id']
    )
}}

with ticker_names as (
    select 
        tp.symbol as symbol,
        coalesce(nm.full_name, 'N/A') as full_name,
        min(tp.timestamp) as start_timestamp
    from {{ source('CryptoPricing', 'ticker_prices') }} tp
    left join {{ ref('name_mapping') }} nm
        on left(tp.symbol, length(tp.symbol) - 4) = nm.abbreviation
    group by symbol, full_name
),

ticker_names_with_id as (
    select 
        {{ dbt_utils.generate_surrogate_key([
            'symbol',
            'full_name',
            'start_timestamp'
        ]) }} as id,
        symbol,
        full_name,
        start_timestamp
    from ticker_names
)

select *
from ticker_names_with_id