import app.database.s3
import app.helpers.event_bridge
import app.helpers.response_builder
from app.helpers.setup_logging import log

import os
import simplejson as json

import time


class Webhook:
    def __init__(self):
        self.exchange_client = app.database.s3.S3(self.exchange_bucket())
        self.downloads_client = app.database.s3.S3(self.downloads_bucket())

    def env(self):
        return os.environ.get('Environment', 'qa')

    def extraction(self, event):
        log.info('Generating extractions response')
        event_data = event.get('detail').get('data')
        application_id = event_data.get('application_id')

        # Fetch document data from S3
        document_uris = event_data.get('document_data_uris')

        document_datas_json = []
        for doc_uri in document_uris:
            # Handles the case if version is not provided in s3 uri
            if '#' in doc_uri:
                key, doc_version = doc_uri.replace("s3://", "").split('/', 1)[1].split('#')
                doc_json = self.exchange_client.get_object(key, doc_version)
            else:
                key = doc_uri.replace("s3://", "").split('/', 1)[1]
                doc_json = self.exchange_client.get_object(key)
            document_datas_json.append(json.loads(doc_json))

        # Build document extraction response data
        response = app.helpers.response_builder.ResponseBuilder \
            .extraction_response(event_data.get('application_reference_id'), document_datas_json, application_id, self.downloads_client)  # noqa: B950

        # Save built response to S3 and push event to ApplicationService
        partner_id = event_data.get('partner_id')

        event_detail = self.upload_to_s3_and_push_event(
            event, 'DeliverExternalResponse', partner_id,
            application_id, response, 'DocumentsExtractionComplete'
        )

        if event_detail == {}:
            return self.failed_webhook()

        return self.successful_webhook(event_detail)

    def verification(self, event):
        log.info('Generating verification response')
        event_data = event.get('detail').get('data')
        application_id = event_data.get('application_id')
        stip_result_uri = event_data.get('stipulation_result_uri')

        # Handles the case if version is not provided in s3 uri
        if '#' in stip_result_uri:
            key, doc_version = stip_result_uri.replace("s3://", "").split('/', 1)[1].split('#')  # noqa: B950
            stipulation_json = json.loads(self.exchange_client.get_object(key, doc_version))
        else:
            key = stip_result_uri.replace("s3://", "").split('/', 1)[1]
            stipulation_json = json.loads(self.exchange_client.get_object(key))

        # Build stipulation response data
        response = app.helpers.response_builder.ResponseBuilder \
            .stipulation_response(stipulation_json, application_id, event_data.get('application_reference_id'))  # noqa: B950

        # Save built response to S3 and push event to Message Delivery Service
        partner_id = event_data.get('partner_id')

        event_detail = self.upload_to_s3_and_push_event(
            event, 'DeliverExternalResponse', partner_id,
            application_id, response, 'StipulationVerificationComplete'
        )

        if event_detail == {}:
            return self.failed_webhook()

        return self.successful_webhook(event_detail)

    def upload_to_s3_and_push_event(self, event, event_type, partner_id, application_id, body, webhook_type):  # noqa: B950

        timestamp = int(time.time() * 1000)
        key = f"{partner_id}/{application_id}/webhooks/{timestamp}.json"
        version = self.exchange_client.put_object(key, json.dumps(body))

        if not version:
            # Putting object into S3 failed
            return {}

        detail = {
            'metadata': {
                'traceparent': ''
            },
            'data': {
                'application_id': application_id,
                'partner_id': partner_id,
                'jwt': event.get('headers', {}).get('jwt', ''),
                'source_detail_type': webhook_type,
                'webhook_url': event.get('detail').get('data').get('webhook_url', ''),
                "response_uri": f"s3://{self.exchange_bucket()}/{key}#{version}"
            }
        }

        if os.environ.get('EVENT_TYPE') == 'local':
            return detail

        app.helpers.event_bridge.EventBridge().push_event(event_type, detail)
        return detail

    def exchange_bucket(self):
        return f"informed-techno-core-{self.env()}-exchange"

    def downloads_bucket(self):
        return f"informed-techno-core-{self.env()}-downloads"

    def successful_webhook(self, event_detail):
        log.info('Reponse Sent Successfully')
        return {
            'status_code': 200,
            'body': json.dumps({
                'message': 'Event processed successfully :)',
                'event_detail': event_detail
            })
        }

    def failed_webhook(self):
        log.info('Response Failed to Send')
        return {
            'status_code': 500,
            'body': json.dumps({'message': 'Something went wrong'})
        }
