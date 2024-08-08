from utils import BinanceHelper
import schemas
import logging

logger = logging.getLogger()
logger.setLevel("INFO")

def lambda_handler(event,context):
    logger.info('### EVENT')
    logger.info(event)

    symbols = ["BTCUSDT", "ETHUSDT", "BNBUSDT", "SOLUSDT"]
    bh = BinanceHelper()

    if event.get('schedule') == 'every_20_min':
        prices = bh.get_latest_ticker_prices(symbols)
        bh.insert_json_into_table(
            table_name="ticker_prices",
            data=prices,
            schema=schemas.ticker_prices_schema
        )
    elif event.get('schedule') == '2_times_a_day':
        volume = bh.get_ticker_price_change_24hrs(symbols)
        bh.insert_json_into_table(
            table_name="ticker_price_change",
            data=volume,
            schema=schemas.ticker_price_change_schema
        )
    else:
        logger.error('Invalid event schedule')
        raise

# lambda_handler({'schedule': 'every_20_min'}, None)