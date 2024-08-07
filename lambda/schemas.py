from google.cloud import bigquery  

ticker_prices_schema = [
    bigquery.SchemaField("id", "STRING", mode="REQUIRED"),
    bigquery.SchemaField("symbol", "STRING"),
    bigquery.SchemaField("price", "FLOAT"),
    bigquery.SchemaField("timestamp", "TIMESTAMP", mode="REQUIRED"),
]

ticker_price_change_schema = [
    bigquery.SchemaField("id", "STRING", mode="REQUIRED"),
    bigquery.SchemaField("symbol", "STRING"),
    bigquery.SchemaField("priceChange", "FLOAT"),
    bigquery.SchemaField("priceChangePercent", "FLOAT"),
    bigquery.SchemaField("weightedAvgPrice", "FLOAT"),
    bigquery.SchemaField("prevClosePrice", "FLOAT"),
    bigquery.SchemaField("lastPrice", "FLOAT"),
    bigquery.SchemaField("lastQty", "FLOAT"),
    bigquery.SchemaField("bidPrice", "FLOAT"),
    bigquery.SchemaField("bidQty", "FLOAT"),
    bigquery.SchemaField("askPrice", "FLOAT"),
    bigquery.SchemaField("askQty", "FLOAT"),
    bigquery.SchemaField("openPrice", "FLOAT"),
    bigquery.SchemaField("highPrice", "FLOAT"),
    bigquery.SchemaField("lowPrice", "FLOAT"),
    bigquery.SchemaField("volume", "FLOAT"),
    bigquery.SchemaField("quoteVolume", "FLOAT"),
    bigquery.SchemaField("openTime", "INTEGER"),
    bigquery.SchemaField("closeTime", "INTEGER"),
    bigquery.SchemaField("firstId", "INTEGER"),
    bigquery.SchemaField("lastId", "INTEGER"),
    bigquery.SchemaField("count", "INTEGER"),
    bigquery.SchemaField("timestamp", "TIMESTAMP", mode="REQUIRED"),
]