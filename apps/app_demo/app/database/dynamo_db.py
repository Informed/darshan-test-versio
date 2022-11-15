import app.helpers.setup_logging

from boto3.dynamodb.conditions import Key
from honeybadger import honeybadger

import boto3
import os


class DynamoDb:
    def __init__(self):
        self.log = app.helpers.setup_logging.SetupLogging()
        self.dynamodb = boto3.resource('dynamodb', region_name=self.region())
        self.table_name = f"techno-core-{self.env()}-app-demo"
        self.table = self.dynamodb.Table(self.table_name)

    def env(self):
        return os.environ.get('Environment', 'qa')

    def region(self):
        return os.environ.get('AWS_REGION', '')

    def get_item(self, keys):
        self.log.info(f"Getting item from DynamoDb with keys - {keys}")
        response = self.table.get_item(Key=keys)

        if response.get('ResponseMetadata', {}).get('HTTPStatusCode') != 200:
            honeybadger.notify(Exception('DynamoDbError'), context={
                'message': 'Dynamo Db get item call failed',
                'request_id': response.get('ResponseMetadata', {}).get('RequestId'),
                'request_keys': keys
            })
            return

        return response.get('Item', {})

    def query_by_index(self, key, value):
        self.log.info(f"Querying index - {key} from DynamoDb with value - {value}")
        index_name = f"{key}_index"
        conditional_exp = Key(key).eq(value)

        response = self.table.query(
            IndexName=index_name,
            KeyConditionExpression=conditional_exp
        )

        if response.get('ResponseMetadata', {}).get('HTTPStatusCode') != 200:
            honeybadger.notify(Exception('DynamoDbError'), context={
                'message': 'Dynamo Db query call failed',
                'request_id': response.get('ResponseMetadata', {}).get('RequestId'),
                'index_name': index_name,
                'key_condition_expression': conditional_exp
            })
            return

        return response.get('Items', [])

    def put_item(self, payload):
        self.log.info('Putting item into DynamoDb')
        response = self.table.put_item(Item=payload)

        if response.get('ResponseMetadata', {}).get('HTTPStatusCode') != 200:
            honeybadger.notify(Exception('DynamoDbError'), context={
                'message': 'Dynamo Db put item call failed',
                'request_id': response.get('ResponseMetadata', {}).get('RequestId'),
                'payload': payload
            })
            return False

        return True
