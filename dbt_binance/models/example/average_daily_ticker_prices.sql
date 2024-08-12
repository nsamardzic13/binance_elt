with final as (
    select
        extract(date from timestamp) as date,
        symbol,
        avg(price) as avg_price
    from {{ source('CryptoPricing', 'ticker_prices') }}
    group by 
        date,
        symbol 
        
)

select *
from final