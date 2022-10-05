import app.database.dynamo_db
import app.helpers.setup_logging

from boto3.dynamodb.conditions import Key
from datetime import datetime
from decimal import Decimal

import boto3
import os
import simplejson as json
import uuid


class PartnerProfile:
    PARTITION_KEY_PREFIX = 'partner_'
    SERVICES_WITH_UNIQUE_CONSTRAINT = ['collectIq', 'metadata', 'verifyIq']
    INSERTION_SERVER_ERROR_MESSAGE = """Uniqueness constraints failed or something went wrong during profile creation :( No data has been inserted into profile service"""  # noqa:B950

    def __init__(self):
        self.log = app.helpers.setup_logging.SetupLogging()
        self.dynamodb = app.database.dynamo_db.DynamoDb()
        self.event_client = boto3.client('events')

    def env(self):
        return os.environ.get('Environment') or 'acceptance'

    def create_profile(self, event):
        self.log.info('Partner Profile Controller - start create_profile')
        self.log.set_attributes(
            {'partner_profile.request.action': 'CreateProfile'}
        )

        data = json.loads(event.body, parse_float=Decimal)
        partner_uuid, prefixed_uuid = self.generate_uuid()

        created_services = []
        unique_services = self.fetch_unique_services(data)
        # insert services with uniqueness constraint first
        # if everything passes, insert the remaining services,
        # else notify partner creation failed
        response = self.dynamodb.create_items_with_condition(
            prefixed_uuid, unique_services
        )
        if response.get('ResponseMetadata', {}).get('HTTPStatusCode') != 200:
            self.log.info(f"UPDATE ERROR: PK - {prefixed_uuid}; Payload  - {unique_services}; DynamoDB response - {response}")  # noqa:B950
            return self.internal_server_error_response(created_services, partner_uuid)
        created_services.append(self.SERVICES_WITH_UNIQUE_CONSTRAINT)

        # insert data into dynamo_db
        for sort_key, payload in data.items():
            if sort_key in self.SERVICES_WITH_UNIQUE_CONSTRAINT:
                continue
            payload = {} if payload is None else payload
            response = self.dynamodb.create_item_with_condition(
                prefixed_uuid, sort_key, payload
            )
            if response.get('ResponseMetadata', {}).get('HTTPStatusCode') != 200:
                self.log.info(f"UPDATE ERROR: PK - {prefixed_uuid}; SK - {sort_key}; Payload  - {payload}; DynamoDB response - {response}")  # noqa:B950
                self.delete_partial_profile(prefixed_uuid, created_services, data)
                return self.internal_server_error_response(created_services, partner_uuid)
            created_services.append(sort_key)

        # send create event to rails api
        profile_payload = self.complete_profile_from_id(partner_uuid)
        self.push_event('CREATE', profile_payload, partner_uuid)

        self.log.info('Partner Profile Controller - end create_profile')
        return profile_payload

    def update_profile(self, event):
        self.log.info('Partner Profile Controller - start update_profile')
        self.log.set_attributes(
            {'partner_profile.request.action': 'UpdateProfile'}
        )

        data = json.loads(event.body, parse_float=Decimal)
        partner_uuid = event.raw_path.split('/')[-1]
        prefixed_uuid = self.PARTITION_KEY_PREFIX + partner_uuid

        # check if partner exists
        profile_payload = self.complete_profile_from_id(partner_uuid)
        if profile_payload.get('statusCode') == 404:
            return {'statusCode': 404}

        updated_services = []
        unique_services = self.fetch_unique_services(data)
        # insert services with uniqueness constraint first
        # if everything passes, insert the remaining services,
        # else notify partner creation failed
        response = self.dynamodb.update_items_with_condition(
            prefixed_uuid, unique_services
        )
        if response.get('ResponseMetadata', {}).get('HTTPStatusCode') != 200:
            self.log.info(f"UPDATE ERROR: PK - {prefixed_uuid}; Payload  - {unique_services}; DynamoDB response - {response}")  # noqa:B950
            return self.internal_server_error_response(updated_services, partner_uuid)
        updated_services.append(self.SERVICES_WITH_UNIQUE_CONSTRAINT)

        # insert data into dynamodb
        for sort_key, payload in data.items():
            if sort_key in self.SERVICES_WITH_UNIQUE_CONSTRAINT:
                continue
            payload = {} if payload is None else payload
            response = self.dynamodb.update_item_with_condition(
                prefixed_uuid, sort_key, payload
            )
            if response.get('ResponseMetadata', {}).get('HTTPStatusCode') != 200:
                self.log.info(f"UPDATE ERROR: PK - {prefixed_uuid}; SK - {sort_key}; Payload  - {payload}; DynamoDB response - {response}")  # noqa:B950
                return self.internal_server_error_response(updated_services, partner_uuid)
            updated_services.append(sort_key)

        # get updated data
        profile_payload = self.complete_profile_from_id(partner_uuid)
        # send update event to rails api
        self.push_event('UPDATE', profile_payload, partner_uuid)

        self.log.info('Partner Profile Controller - end update_profile')
        return profile_payload

    def fetch_unique_services(self, data):
        unique_services = {}
        for key in self.SERVICES_WITH_UNIQUE_CONSTRAINT:
            if not data.get(key):
                continue

            unique_services[key] = data.get(key)
        return unique_services

    def internal_server_error_response(self, successful_services, partner_uuid):
        return {
            'statusCode': 500,
            'message': self.INSERTION_SERVER_ERROR_MESSAGE,
            'successfully_updated_services': successful_services,
            'id': partner_uuid
        }

    def complete_profile_from_id(self, partner_uuid):
        self.log.info('Partner Profile Controller - start complete_profile_from_id')
        self.log.set_attributes(
            {'partner_profile.request.action': 'GetCompleteProfileFromId'}
        )

        prefixed_uuid = self.PARTITION_KEY_PREFIX + partner_uuid
        items = self.dynamodb.query_table('PK', prefixed_uuid)
        if items == []:
            return {'statusCode': 404}

        self.log.info('Partner Profile Controller - end complete_profile_from_id')
        return self.sanitize_query_response(items)

    def complete_profile_from_name(self, partner_name):
        self.log.info('Partner Profile Controller - start complete_profile_from_name')
        self.log.set_attributes(
            {'partner_profile.request.action': 'GetCompleteProfileFromName'}
        )

        partner_uuid = self.fetch_partner_uuid_from_name(partner_name)

        if not partner_uuid:
            return {'statusCode': 404}

        self.log.info('Partner Profile Controller - end complete_profile_from_name')
        return self.complete_profile_from_id(partner_uuid)

    def service_profile_from_id(self, partner_uuid, service):
        self.log.info('Partner Profile Controller - start service_profile_from_id')
        self.log.set_attributes(
            {'partner_profile.request.action': 'GetServiceFromId'}
        )

        prefixed_uuid = self.PARTITION_KEY_PREFIX + partner_uuid
        item = self.dynamodb.fetch_item(prefixed_uuid, service)

        if item == {}:
            return {'statusCode': 404}

        clean_item, pk, sk = self.sanitize_node(item)
        response = {'id': pk}
        response[sk] = clean_item

        self.log.info('Partner Profile Controller - end service_profile_from_id')
        return response

    def service_profile_from_name(self, partner_name, service):
        self.log.info('Partner Profile Controller - start service_profile_from_name')
        self.log.set_attributes(
            {'partner_profile.request.action': 'GetServiceFromName'}
        )

        partner_uuid = self.fetch_partner_uuid_from_name(partner_name)

        if not partner_uuid:
            return {'statusCode': 404}

        self.log.info('Partner Profile Controller - end service_profile_from_name')
        return self.service_profile_from_id(partner_uuid, service)

    def partner_from_query_params(self, params):
        self.log.info('Partner Profile Controller - start partner_from_query_params')

        # Case 1: 'email': 'acmefinancial@driveinformed.com'
        if 'email' in params.keys():
            self.log.set_attributes(
                {'partner_profile.request.action': 'GetServiceFromEmail'}
            )

            conditional_exp = Key('gsi1pk').eq(params.get('email', ''))
            items = self.dynamodb.query_table_by_index('gsi1pk_index', conditional_exp)

            self.log.info('Partner Profile Controller - end partner_from_query_params')
            return self.sanitize_query_response(items)
        # Case 2: { 'service': 'collectIq', 'subdomain': 'acmefinancial' }
        # or { 'service': 'verifyIq', 'subdomain': 'acmefinancial' }
        elif 'subdomain' in params.keys() and \
             params.get('service', '') in ['collectIq', 'verifyIq']:
            self.log.set_attributes(
                {'partner_profile.request.action': 'GetServiceFromSubdomain'}
            )

            conditional_exp = Key('gsi1pk').eq(params.get('subdomain', '')) \
                & Key('SK').eq(params.get('service', ''))
            items = self.dynamodb.query_table_by_index('gsi1pk_index', conditional_exp)

            self.log.info('Partner Profile Controller - end partner_from_query_params')
            return self.sanitize_query_response(items)
        else:
            self.log.set_attributes(
                {'partner_profile.request.action': 'InvalidQueryParams'}
            )

            self.log.info('Partner Profile Controller - end partner_from_query_params')
            return {'statusCode': 400, 'message': 'Invalid query params!'}

    def partners_from_query_params(self, params):
        self.log.info('Partner Profile Controller - start partners_from_query_params')

        # Case 1: { 'service': 'redaction' }
        if 'service' in params.keys():
            self.log.set_attributes(
                {'partner_profile.request.action': 'GetServiceFromAllPartners'}
            )

            items = self.dynamodb.scan_table('SK', params.get('service', None))

            response = []
            for item in items:
                clean_item, pk, sk = self.sanitize_node(item)
                item_hash = {'id': pk}
                item_hash[sk] = clean_item
                response.append(item_hash)

            self.log.info('Partner Profile Controller - end partners_from_query_params')
            return {'items': response}
        else:
            self.log.set_attributes(
                {'partner_profile.request.action': 'InvalidQueryParams'}
            )

            self.log.info('Partner Profile Controller - end partners_from_query_params')
            return {'statusCode': 400, 'message': 'Invalid query params!'}

    def fetch_partner_uuid_from_name(self, partner_name):
        conditional_exp = Key('gsi2pk').eq(partner_name)
        items = self.dynamodb.query_table_by_index('gsi2pk_index', conditional_exp)
        return self.sanitize_query_response(items).get('id', None)

    def sanitize_query_response(self, items):
        if items == []:
            return {'statusCode': 404}

        response = {}
        pk = None
        for item in items:
            if 'SK' not in item.keys():
                continue

            key = item['SK']
            response[key], pk, _ = self.sanitize_node(item)

        response['id'] = pk
        return response

    def sanitize_node(self, item):
        pk = item.get('PK', '').replace(self.PARTITION_KEY_PREFIX, '')
        sk = item.get('SK', '')
        item.pop('PK', None)
        item.pop('SK', None)
        item.pop(app.database.dynamo_db.DynamoDb.VERSION_KEY, None)
        return [item, pk, sk]

    def generate_uuid(self):
        partner_uuid = str(uuid.uuid4())
        prefixed_uuid = self.PARTITION_KEY_PREFIX + partner_uuid

        items = self.dynamodb.query_table('PK', prefixed_uuid)
        if items:
            return self.generate_uuid()

        return [partner_uuid, prefixed_uuid]

    def push_event(self, event_type, profile_payload, partner_uuid):
        partner_payload = profile_payload.get('metadata', {})
        self.event_client.put_events(Entries=[
            {
                'Time': datetime.now(),
                'Source': "tc-{env}-profile-update".format(env=self.env()),
                'EventBusName': "techno-core-{env}".format(env=self.env()),
                'DetailType': event_type,
                'Detail': json.dumps({
                    'uuid': partner_uuid,
                    'name': partner_payload.get('name'),
                    'email': partner_payload.get('email'),
                    'tollFreeNumber': partner_payload.get('tollFreeNumber'),
                    'collectIqSubdomain': profile_payload.get('collectIq', {}).get('subdomain'),
                    'verifyIqSubdomain': profile_payload.get('verifyIq', {}).get('subdomain')
                })
            }
        ],)

    def delete_partial_profile(self, partition_key, services, data):
        for sort_key in services:
            if sort_key not in data.keys():
                continue
            self.dynamodb.delete_item(partition_key, sort_key)

    def health_check_partner_profile(self):
        healthy = self.dynamodb.health_check_table()
        if healthy:
            return {'statusCode': 200}
        else:
            return {'statusCode': 500, 'message': 'Dynamo db is not responding'}
