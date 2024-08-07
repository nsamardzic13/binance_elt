import os
import requests
import yaml
import json
import hmac
import hashlib
import time
import boto3
import json
import uuid
from typing import Union
from datetime import datetime

from google.cloud import bigquery
from google.oauth2 import service_account


class BqHelper:
    def __init__(self, config_path: Union[str, None] = None) -> None:
        if not config_path:
                self._aws_secret_name = os.environ['aws_secret_name']
                self._aws_region = os.environ['aws_region']
                self._bq_dataset = os.environ['bq_dataset']
        else:
            with open(config_path, 'r') as f:
                config = yaml.load(f, Loader=yaml.SafeLoader)
                self._aws_secret_name = config['aws_secret_name']
                self._aws_region = config['aws_region']
                self._bq_dataset = config['bq_dataset']
        
        self._bq_project_id = self._get_project_id()
        self.bq_client = self._get_bq_client()

    def _get_project_id(self) -> str:
        credentials_info = self._get_secret()
        return credentials_info['project_id']

    def _get_bq_client(self) -> bigquery.Client:
        credentials_info = self._get_secret()
        credentials = service_account.Credentials.from_service_account_info(credentials_info)
        bq_client = bigquery.Client(credentials=credentials, project=credentials_info['project_id'])
        return bq_client
    
    def _create_table_if_not_exists(self, table_id: str, schema: str) -> None:
        try:
            self.bq_client.get_table(table_id)
            print(f"Table {table_id} already exists")
        except:
            table = bigquery.Table(table_id, schema=schema)
            self.bq_client.create_table(table)
            print(f"Created table {table_id}")
            
            # wait for table to get created
            time.sleep(30)

    def insert_json_into_table(self, table_name: str, data: list, schema: str) -> None:
        table_id = f"{self._bq_project_id}.{self._bq_dataset}.{table_name}"
        self._create_table_if_not_exists(table_id, schema)
        errors = self.bq_client.insert_rows_json(table_id, data)

        if errors:
            print(f"Encountered errors while inserting rows: {errors}")
        else:
            print(f"Rows have been successfully inserted to {table_name}")

class BinanceHelper(BqHelper):
    def __init__(self, config_path: Union[str, None] = None) -> None:
        super().__init__(config_path)
        if not config_path:
            self._api_key = os.environ['api_key']
            self._secret_key = os.environ['secret_key']
        else:
            with open(config_path, 'r') as f:
                config = yaml.load(f, Loader=yaml.SafeLoader)
                self._api_key = config['api_key']
                self._secret_key = config['secret_key']

        self._base_endpoint = 'https://api.binance.com'
        self._headers = {
            "Content-Type": "application/json;charset=utf-8",
            "X-MBX-APIKEY": self._api_key
        }
        self._current_timestamp = datetime.utcnow().isoformat()
    
    def _get_secret(self) -> dict:
        session = boto3.session.Session()
        client = session.client(
            service_name='secretsmanager',
            region_name=self._aws_region
        )

        try:
            get_secret_value_response = client.get_secret_value(
                SecretId=self._aws_secret_name
            )
        except Exception as e:
            raise e

        secret = get_secret_value_response['SecretString']
        return json.loads(secret)

    def _get_timestamp(self) -> int:
        return int(time.time() * 1000)

    def _create_signature(self, params) -> str:
        query_string = '&'.join([f"{key}={params[key]}" for key in sorted(params)])
        return hmac.new(self._secret_key.encode('utf-8'), query_string.encode('utf-8'), hashlib.sha256).hexdigest()

    def _add_metadata(self, data: list) -> list:
        for el in data:
            el["id"] = str(uuid.uuid4())
            el["timestamp"] = self._current_timestamp
        
        return data

    def _get_json_response_get(self, url: str, headers: dict, params: dict) -> list:
        response = requests.get(
            url=url,
            headers=headers,
            params=params
        )
        if response.status_code != 200:
            print(f"Error: {response.status_code}")
            print(response.text)
            raise response.text
        
        data = response.json()
        return data

    def get_latest_ticker_prices(self, symbols: Union[list, None] = None) -> list:
        params = {}
        if symbols:
            json_str = json.dumps(symbols, separators=(',', ':'))
            params["symbols"] = json_str

        data = self._get_json_response_get(
            url=self._base_endpoint + '/api/v3/ticker/price',
            headers=self._headers,
            params=params
        )

        data = self._add_metadata(data)
        return data
    
    def get_ticker_price_change_24hrs(self, symbols: Union[list, None] = None, type: str = 'MINI'):
        params = {}
        if symbols:
            json_str = json.dumps(symbols, separators=(',', ':'))
            params["symbols"] = json_str

        data = self._get_json_response_get(
            url=self._base_endpoint + '/api/v3/ticker/24hr',
            headers=self._headers,
            params=params
        )

        data = self._add_metadata(data)
        return data