from utils import BinanceHelper
import schemas

def lambda_handler(event,context):
    symbols = ["BTCUSDT", "ETHUSDT", "BNBUSDT", "SOLUSDT"]
    bh = BinanceHelper(config_path='config.yml')
    
    if event.get('schedule') == 'every_20_min':
        prices = bh.get_latest_ticker_prices(symbols)
        bh.insert_json_into_table(
            table_name="ticker_prices",
            data=prices,
            schema=schemas.ticker_prices_schema
        )

    if event.get('schedule') == '2_times_a_day':
        volume = bh.get_ticker_price_change_24hrs(symbols)
        bh.insert_json_into_table(
            table_name="ticker_price_change",
            data=volume,
            schema=schemas.ticker_price_change_schema
        )

# lambda_handler(None, None)