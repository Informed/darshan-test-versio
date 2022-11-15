import datetime
import os
import re
import uuid
from decimal import Decimal
from urllib.parse import parse_qs

import simplejson as json

from app.database.dynamo_db import DynamoDb
import app.database.s3
from app.helpers.application_orchestrator import ApplicationOrchestrator
from app.helpers.opentelemetry import Opentelemetry
import app.helpers.recorder
import app.helpers.setup_logging

from .base_controller import BaseController


class DocumentsController(BaseController):
    BOOLEAN_REGEX = "^true$|^false$"

    def setup(self):
        self.dynamodb = DynamoDb()
        self.otel = Opentelemetry()

    def create_documents_upload_urls(self, application_id):
        self.log.info('Api Handler: creating documents upload urls')
        partner_info = self.event.get('partner_info')
        partner_id = partner_info.get('partner_uuid')

        body = json.loads(self.event.body, parse_float=Decimal)
        # TODO: validate the json body?

        if not self.application_valid(application_id):
            return {
                'status_code': 400,
                'error_message': 'Application does not exist'
            }

        file_names = body.get('image_files', [])
        if len(file_names) != len(set(file_names)):
            return {
                'status_code': 400,
                'error_message': 'Input files must be unique'
            }

        # process image files
        base_key = f"{partner_id}/{application_id}"
        img_files_response, img_files_event = self.process_image_files(
            file_names, base_key)

        # process structured data
        digital_data = body.get('structured_data', [])
        structured_data_response, structured_data_event = self.process_structured_data(digital_data, base_key)  # noqa: B950

        # track request
        additional_info = {
            "image_files": img_files_event,
            "structured_data": structured_data_event
        }
        request_id = self.recorder.generate_uuid('app_request')
        self.recorder.track_request(
            application_id, request_id, 'documents_upload', additional_info
        )

        # push DocumentsPosted event
        self.push_event(
            application_id, partner_id, img_files_event, structured_data_event
        )

        response_payload = {
            "request_id": request_id,
            "image_files": img_files_response,
            "structured_data": structured_data_response
        }
        return response_payload

    def get_documents(self, application_id):
        params = self.event.query_string_parameters or {}
        pages = params.get('pages', 'false')

        if not re.search(self.BOOLEAN_REGEX, pages):
            return self.build_response(400, 'Incorrect query parameter - pages')

        # Verify if the application id belongs to the partner
        partner_id = self.event.get('partner_info', {}).get('partner_uuid')
        if not self.application_belongs_to_partner(partner_id, application_id):
            return self.build_response(400, 'Application not found!')

        return ApplicationOrchestrator().documents(self.version, application_id, pages)

    def process_image_files(self, file_names, base_key):
        image_files = []
        event_image_files = []
        bucket = os.environ.get('AWS_UPLOADS_BUCKET')
        s3_client = app.database.s3.S3(bucket)

        for file_name in file_names:
            file_id = str(uuid.uuid4())
            file_key = f"{base_key}/default_{file_id}"
            presigned_url = s3_client.generate_presigned_url(file_key, 3600)

            event_image_files.append({
                "file_reference_id": file_name,
                "file_id": file_id
            })

            image_files.append({
                "file_reference_id": file_name,
                "file_id": file_id,
                "url": presigned_url,
                "expiration": self.strip_expiration(presigned_url)
            })
        return image_files, event_image_files

    def process_structured_data(self, digital_data, base_key):
        structured_data = []
        event_structured_data = []

        for digital_doc in digital_data:
            event_payload = self.upload_to_s3_and_construct_event_payload(
                digital_doc, base_key)
            event_structured_data.append(event_payload)

            structured_data.append({
                "document_reference_id": digital_doc.get("document_reference_id"),
                "document_id": event_payload.get("document_id"),
                "document_type": digital_doc.get("document_type")
            })

        return structured_data, event_structured_data

    def upload_to_s3_and_construct_event_payload(self, digital_data, base_key):
        document_id = str(uuid.uuid4())
        key = f"{base_key}/app_request/{document_id}.json"
        version = self.s3.put_object(key, json.dumps(digital_data))

        event_payload = {
            "document_id": document_id,
            "uri": f"s3://{self.bucket()}/{key}#{version}"
        }
        return event_payload

    def push_event(self, app_id, partner_id, image_files, structured_data):  # noqa: B950
        details = {
            "metadata": {
                "traceparent": self.otel.traceparent()
            },
            "data": {
                "application_id": app_id,
                "partner_id": partner_id,
                "jwt": "",
                "image_files": image_files,
                "structured_data": structured_data
            }
        }
        app.helpers.event_bridge.EventBridge().push_event('DocumentsPosted', details)

    def strip_expiration(self, url):
        parsed_url = parse_qs(url)
        sent_date = datetime.datetime.strptime(
            parsed_url['X-Amz-Date'][0], '%Y%m%dT%H%M%SZ')
        expires_in = int(parsed_url['X-Amz-Expires'][0])
        expire_date = sent_date + datetime.timedelta(seconds=expires_in)
        return expire_date.strftime('%Y-%m-%dT%H:%M:%SZ')

    def application_valid(self, application_id):
        item = self.dynamodb.get_item({'PK': application_id, 'SK': 'application'})

        if not item:
            return False

        return True

    def application_belongs_to_partner(self, partner_id, application_id):
        item = self.dynamodb.get_item({'PK': application_id, 'SK': 'application'})
        # ref_id is a combination of partner id and application reference id
        ref_id = item.get('gsi1pk', '')
        # check if partner_id is present in ref_id
        return True if re.search(partner_id, ref_id) else False
