import app.database.dynamo_db

from time import gmtime, strftime

import uuid


class Recorder:
    def __init__(self):
        self.dynamodb = app.database.dynamo_db.DynamoDb()

    def generate_uuid(self, item_type):
        new_uuid = str(uuid.uuid4())
        payload = {'PK': new_uuid, 'SK': item_type}

        items = self.dynamodb.get_item(payload)
        if items:
            return self.generate_uuid()

        return new_uuid

    def track_request(self, application_id, request_reference_id, request_type, additional_info=None):  # noqa: B950
        payload = {
            'PK': request_reference_id,
            'SK': 'app_request',
            'gsi1pk': application_id,
            # 'Mon, 27 Jun 2022 22:11:06 +0000'
            'created_at': strftime("%a, %d %b %Y %H:%M:%S +0000", gmtime()),
            'request_type': request_type
        }

        if additional_info:
            payload['metadata'] = additional_info

        self.dynamodb.put_item(payload)

    def create_application_record(self, application_id, partner_application_id):
        payload = {
            'PK': application_id,
            'SK': 'application',
            'gsi1pk': partner_application_id,
            # 'Mon, 27 Jun 2022 22:11:06 +0000'
            'created_at': strftime("%a, %d %b %Y %H:%M:%S +0000", gmtime())
        }
        self.dynamodb.put_item(payload)

    def update_application_record(self, application_id):
        item = self.dynamodb.get_item({'PK': application_id, 'SK': 'application'})
        item['updated_at'] = strftime("%a, %d %b %Y %H:%M:%S +0000", gmtime())
        self.dynamodb.put_item(item)
