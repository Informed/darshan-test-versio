import app.database.serializer
import app.database.unique_key
import app.helpers.setup_logging

from boto3.dynamodb.conditions import Key, Attr

import boto3
import os


class DynamoDb:
    VERSION_KEY = 'version'

    def __init__(self):
        self.log = app.helpers.setup_logging.SetupLogging()
        self.dynamodb = boto3.resource('dynamodb', region_name=self.region())
        self.table_name = f"techno-core-{self.env()}-partner-profile"
        self.table = self.dynamodb.Table(self.table_name)
        self.client = self.dynamodb.meta.client

    def env(self):
        return os.environ.get('Environment', 'acceptance')

    def region(self):
        return os.environ.get('AWS_REGION', '')

    def fetch_item_with_version(self, partition_key, sort_key):
        item = self.fetch_item(partition_key, sort_key)
        return [item, item.get(DynamoDb.VERSION_KEY)]

    def fetch_item(self, partition_key, sort_key):
        item = self.table.get_item(Key={'PK': partition_key, 'SK': sort_key}).get('Item', {})
        if item is None or not any(item):
            return item

        return self.deserialize_item(sort_key, item)

    def deserialize_item(self, sort_key, item):
        return app.database.serializer.Serializer().base_deserialize(sort_key, item)

    def create_items_with_condition(self, partition_key, data):
        transaction_items = []
        for sort_key, item in data.items():
            transaction_items += self.build_create_transaction_items(
                partition_key, sort_key, item
            )

        return self.client.transact_write_items(
            TransactItems=transaction_items
        )

    def create_item_with_condition(self, partition_key, sort_key, item):
        transaction_items = self.build_create_transaction_items(partition_key, sort_key, item)

        return self.client.transact_write_items(
            TransactItems=transaction_items
        )

    def build_create_transaction_items(self, partition_key, sort_key, item):
        item = {} if item is None else item
        item.update({'PK': partition_key, 'SK': sort_key})

        unique_keys = app.database.unique_key.UniqueKey(sort_key).create_unique_keys(item)
        item = self.serialize_item(sort_key, item)
        item[DynamoDb.VERSION_KEY] = 1

        condition = 'attribute_not_exists(PK)'

        items = [
            {
                'Put': {
                    'TableName': self.table_name,
                    'Item': item,
                    'ConditionExpression': condition
                }
            }
        ]
        for key in unique_keys:
            items.append({
                'Put': {
                    'TableName': self.table_name,
                    'Item': key,
                    'ConditionExpression': condition
                }
            })

        return items

    def update_items_with_condition(self, partition_key, data):
        transaction_items = []
        for sort_key, payload in data.items():
            transaction_items += self.build_update_transaction_items(
                partition_key, sort_key, payload
            )

        return self.client.transact_write_items(
            TransactItems=transaction_items
        )

    def update_item_with_condition(self, partition_key, sort_key, payload):
        transaction_items = self.build_update_transaction_items(
            partition_key, sort_key, payload
        )

        return self.client.transact_write_items(
            TransactItems=transaction_items
        )

    def build_update_transaction_items(self, partition_key, sort_key, payload):
        item, prev_version = self.fetch_item_with_version(partition_key, sort_key)
        payload = {} if payload is None else payload
        payload.update({'PK': partition_key, 'SK': sort_key})

        put_keys, delete_keys = app.database.unique_key.UniqueKey(sort_key) \
                                   .update_unique_keys(payload, item)

        payload = self.serialize_item(sort_key, payload)
        payload[DynamoDb.VERSION_KEY] = 1 if prev_version is None else prev_version + 1

        primary_condition = 'version = :version OR attribute_not_exists(version)'
        expression_attr_values = {':version': prev_version}
        unique_key_condition = 'attribute_not_exists(PK)'

        items = [
            {
                'Put': {
                    'TableName': self.table_name,
                    'Item': payload,
                    'ConditionExpression': primary_condition,
                    'ExpressionAttributeValues': expression_attr_values
                }
            }
        ]

        for key in put_keys:
            items.append({
                'Put': {
                    'TableName': self.table_name,
                    'Item': key,
                    'ConditionExpression': unique_key_condition
                }
            })

        for key in delete_keys:
            items.append({
                'Delete': {
                    'TableName': self.table_name,
                    'Key': key
                }
            })

        return items

    def serialize_item(self, sort_key, item):
        return app.database.serializer.Serializer().base_serialize(sort_key, item)

    def query_table(self, key=None, value=None):
        conditional_exp = Key(key).eq(value)
        items = self.table.query(KeyConditionExpression=conditional_exp).get('Items', [])
        return [self.deserialize_item(item['SK'], item) for item in items]

    def query_table_by_index(self, index_name, conditional_exp=None):
        items = self.table.query(
            IndexName=index_name,
            KeyConditionExpression=conditional_exp
        ).get('Items', [])
        return [self.deserialize_item(item['SK'], item) for item in items]

    def scan_table(self, key=None, value=None):
        if key is not None and value is not None:
            filter_exp = Attr(key).eq(value)
            items = self.table.scan(FilterExpression=filter_exp).get('Items', [])

            return [self.deserialize_item(item['SK'], item) for item in items]
        else:
            return []

    def delete_item(self, partition_key, sort_key):
        item = self.fetch_item(partition_key, sort_key)

        delete_items = [{'PK': partition_key, 'SK': sort_key}]
        delete_items += app.database.unique_key.UniqueKey(sort_key).delete_unique_keys(item)

        with self.table.batch_writer() as batch:
            for item in delete_items:
                batch.delete_item(Key=item)

    def health_check_table(self):
        try:
            res = self.client.describe_table(TableName=self.table_name)
            if res:
                return True
        except self.client.exceptions.ResourceNotFoundException:
            return False
