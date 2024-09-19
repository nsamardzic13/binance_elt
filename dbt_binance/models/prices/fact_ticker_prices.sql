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
        round(
            (tp.highPrice + tp.lowPrice) / 2, 
            2
        ) as price,
        round(tp.priceChange, 2) as price_change,
        round(tp.priceChangePercent, 2) as price_change_percent,
        round(tp.weightedAvgPrice, 2) as weighted_avg_price,
        round(tp.prevClosePrice, 2) as prev_close_price,
        round(tp.lastPrice, 2) as last_price,
        round(tp.lastQty, 2) as last_qty,
        round(tp.bidPrice, 2) as bid_price,
        round(tp.bidQty, 2) as bid_qty,
        round(tp.askPrice, 2) as ask_price,
        round(tp.askQty, 2) as ask_qty,
        round(tp.openPrice, 2) as open_price,
        round(tp.highPrice, 2) as high_price,
        round(tp.lowPrice, 2) as low_price,
        round(tp.volume, 2) as volume,
        tp.firstId as first_id,
        tp.lastId as last_id,
        tp.count as count,
        TIMESTAMP_MILLIS(tp.openTime) as open_time,
        TIMESTAMP_MILLIS(tp.closeTime) as close_time
    from {{ source('BinanceCryptoDataset', 'ticker_price_change') }} tp
    inner join {{ ref('dim_tickers') }} dt
        on tp.symbol = dt.symbol
    inner join {{ ref('dim_date') }} dd
        on dd.full_date = extract(date from tp.timestamp)
    
    {% if is_incremental() %}
    
    where extract(date from tp.timestamp) >= current_date - {{ var('days_to_ingest') }}
    
    {% endif %}
),

recent_data_with_id as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'symbol_id',
            'date_id',
            'price',
            'open_time'
        ]) }} as id,
        symbol_id,
        date_id,
        price,
        price_change,
        price_change_percent,
        weighted_avg_price,
        prev_close_price,
        last_price,
        last_qty,
        bid_price,
        bid_qty,
        ask_price,
        ask_qty,
        open_price,
        high_price,
        low_price,
        volume,
        first_id,
        last_id,
        count,
        open_time,
        close_time
    from recent_data
),

final as (
    select
        *,
        current_timestamp as updated_timestamp
    from
        recent_data_with_id
)

select *
from final