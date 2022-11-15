from app.helpers.setup_logging import log
from app.helpers.event_bridge import EventBridge

from .base_controller import BaseController

import simplejson as json
from decimal import Decimal


class EditController(BaseController):
    def document(self, app_id, document_id):
        log.info('Api Handler: processing an edit document request')
        partner_info = self.event.get('partner_info')
        partner_id = partner_info.get('partner_uuid')
        body = json.loads(self.event.body, parse_float=Decimal)
        body['document_id'] = document_id
        jwt = self.event.headers.get('jwt')

        log.info('Api Handler: saving document edit request to dynamo db')
        request_id = self.recorder.generate_uuid('app_request')
        self.recorder.track_request(app_id, request_id, 'edit_document')

        if not self.upload_to_s3_and_push_event(
            'DocumentUpdated', body, partner_id, app_id, request_id, document_id, jwt
        ):
            return self.build_response(500, 'Something went wrong :(')

        return {'request_id': request_id}

    def upload_to_s3_and_push_event(self, event_type, body, partner_id, app_id, request_id, document_id, jwt):  # noqa: B950
        log.info('Api Handler: upload edit request to S3')
        key = f"{partner_id}/{app_id}/app_request/{request_id}.json"
        version = self.s3.put_object(key, json.dumps(body))

        if not version:
            return False

        details = {
            'metadata': {
                'traceparent': ''
            },
            'data': {
                'application_id': app_id,
                'partner_id': partner_id,
                'jwt': jwt,
                'document_id': document_id,
                'edit_request_uri': f"s3://{self.bucket()}/{key}#{version}"
            }
        }

        log.info(f"Api Handler: push {event_type} event")
        EventBridge().push_event(event_type, details)
        return True
