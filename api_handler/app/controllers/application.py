import app.database.dynamo_db
import app.database.s3
import app.helpers.application_orchestrator
import app.helpers.event_bridge
import app.helpers.setup_logging
import app.helpers.recorder
import app.helpers.opentelemetry
import app.helpers.partner_profile

from decimal import Decimal

import os
import re
import simplejson as json


class Application:
    BOOLEAN_REGEX = r"^true$|^false$"
    DATE_REGEX = r"^20[0-2][0-9]-((0[1-9])|(1[0-2]))-(0[1-9]|[1-2][0-9]|3[0-1])$"
    DATE_TIME_REGEX = r"^20[0-2][0-9]-((0[1-9])|(1[0-2]))-(0[1-9]|[1-2][0-9]|3[0-1])T([01]\d|2[0-3]):([0-5]\d):([0-5]\d)$"  # noqa: B950
    EMPTY_STRING_REGEX = r"^(?![\s\S])$"
    LIMIT_REGEX = r"^([1-9][0-9]{0,2}|1000)$"

    def __init__(self):
        self.log = app.helpers.setup_logging.SetupLogging()
        self.dynamodb = app.database.dynamo_db.DynamoDb()
        self.recorder = app.helpers.recorder.Recorder()
        self.otel = app.helpers.opentelemetry.Opentelemetry()
        self.s3 = app.database.s3.S3(self.bucket())

    def bucket(self):
        return os.environ.get('AWS_DEFAULT_BUCKET')

    def env(self):
        return os.environ.get('Environment', 'qa')

    def get_applications(self, event, version):
        params = event.query_string_parameters or {}
        partner_id = event.get('partner_info', {}).get('partner_uuid')

        valid_params = {"partner_id": partner_id}
        updated_before = params.get('updated_before', '')
        if not re.search(f"{self.DATE_REGEX}|{self.DATE_TIME_REGEX}|{self.EMPTY_STRING_REGEX}", updated_before):  # noqa: B950
            return self.build_response(400, 'Incorrect query parameter - updated_before')
        valid_params["updated_before"] = updated_before

        updated_after = params.get('updated_after', '')
        if not re.search(f"{self.DATE_REGEX}|{self.DATE_TIME_REGEX}|{self.EMPTY_STRING_REGEX}", updated_after):  # noqa: B950
            return self.build_response(400, 'Incorrect query parameter - updated_after')
        valid_params["updated_after"] = updated_after

        limit = params.get('limit', '25')
        if not re.search(self.LIMIT_REGEX, limit):
            return self.build_response(400, 'Incorrect query parameter - limit')
        valid_params["limit"] = limit

        # TODO: uncomment this when we start supporting pagination
        # starting_after = params.get('starting_after', '')
        # if starting_after != '':
        #     if not self.application_exists(starting_after):
        #         return self.build_response(400, 'Application does not exist')
        #     if updated_before == '' or updated_after == '':
        #         return self.build_response(400, 'Incorrect query parameters - updated_before or updated_after missing')  # noqa: B950
        # valid_params["starting_after"] = starting_after

        return app.helpers.application_orchestrator.ApplicationOrchestrator().applications(version, valid_params)  # noqa: B950

    def create_application(self, event, version):
        self.log.info('Api Handler: creating a new application')
        partner_info = event.get('partner_info')

        body = json.loads(event.body, parse_float=Decimal)
        if not self.validate_event_body(body, partner_info.get('partner_uuid')):
            return self.build_response(400, 'Invalid services requested, please contact support for more information.')  # noqa: B950

        application_reference_id = f"{partner_info.get('partner_uuid')}_{body.get('application_reference_id')}"  # noqa: B950
        # Check if the application already exists, also add application_id to error response
        stored_application_id = self.application_ref_exists(application_reference_id)
        if stored_application_id is not None:
            response = self.build_response(400, 'Application already exists')
            response['application_id'] = stored_application_id
            return response

        application_id = self.recorder.generate_uuid('application')

        # Save the application details in dynamo db
        self.recorder.create_application_record(application_id, application_reference_id)

        request_reference_id = self.recorder.generate_uuid('app_request')
        # Save the request details in dynamo db
        self.recorder.track_request(application_id, request_reference_id, 'create_application')

        self.log.set_attributes(
            {
                'api_handler.request.action': 'CreateApplication',
                'api_handler.request.partner_name': partner_info.get('name'),
                'api_handler.request.application_id': application_id,
                'api_handler.request.request_reference_id': request_reference_id
            }
        )

        # Upload the body into s3 and push create event
        if not self.upload_to_s3_and_push_event(
            event, 'ApplicationCreated', partner_info,
            application_id, body, request_reference_id
        ):
            return self.build_response(500, 'Something went wrong :(')

        return {'application_id': application_id, 'status': 'Ready'}

    def update_application(self, event, version, application_id):
        self.log.info('Api Handler: updating a existing application')
        partner_info = event.get('partner_info')

        body = json.loads(event.body, parse_float=Decimal)
        if not self.validate_event_body(body, partner_info.get('partner_uuid')):
            return self.build_response(400, 'Invalid services requested, please contact support for more information.')  # noqa: B950

        application_reference_id = f"{partner_info.get('partner_uuid')}_{body.get('application_reference_id')}"  # noqa: B950
        # Check if the application does not exist
        if not self.application_ref_exists(application_reference_id):
            return self.build_response(400, 'Application does not exist')

        # Verify if the application id matches the respective partner application id
        if not self.application_valid(application_id, application_reference_id):
            return self.build_response(400, 'ApplicationId does not match application_reference_id')  # noqa: B950

        # Update the application record timestamps
        self.recorder.update_application_record(application_id)

        request_reference_id = self.recorder.generate_uuid('app_request')
        # Save the request details in dynamo db
        self.recorder.track_request(application_id, request_reference_id, 'update_application')

        self.log.set_attributes(
            {
                'api_handler.request.action': 'UpdateApplication',
                'api_handler.request.partner_name': partner_info.get('name'),
                'api_handler.request.application_id': application_id,
                'api_handler.request.request_reference_id': request_reference_id
            }
        )

        # Upload the body into s3 and push update event
        if not self.upload_to_s3_and_push_event(
            event, 'ApplicationUpdated', partner_info,
            application_id, body, request_reference_id
        ):
            return self.build_response(500, 'Something went wrong :(')

        return {'application_id': application_id, 'status': 'Ready'}

    def get_application(self, event, version, application_id):
        params = event.query_string_parameters or {}
        all_questions = params.get('all_questions', 'false')

        if not re.search(self.BOOLEAN_REGEX, all_questions):
            return self.build_response(400, 'Incorrect query parameter - all_questions')

        # Verify if the application id belongs to the partner
        partner_id = event.get('partner_info', {}).get('partner_uuid')
        if not self.application_belongs_to_partner(partner_id, application_id):
            return self.build_response(400, 'Application not found!')

        return app.helpers.application_orchestrator.ApplicationOrchestrator().application(version, application_id, all_questions)  # noqa: B950

    def application_ref_exists(self, application_reference_id):
        items = self.dynamodb.query_by_index('gsi1pk', application_reference_id)
        return items[0].get('PK') if items else None

    def application_exists(self, application_id):
        item = self.dynamodb.get_item({'PK': application_id, 'SK': 'application'})
        return True if item else False

    def application_valid(self, application_id, application_reference_id):
        item = self.dynamodb.get_item({'PK': application_id, 'SK': 'application'})

        if not item:
            return False

        stored_application_reference_id = item.get('gsi1pk')
        if stored_application_reference_id != application_reference_id:
            return False

        return True

    def application_belongs_to_partner(self, partner_id, application_id):
        item = self.dynamodb.get_item({'PK': application_id, 'SK': 'application'})
        # ref_id is a combination of partner id and application reference id
        ref_id = item.get('gsi1pk', '')
        # check if partner_id is present in ref_id
        return True if re.search(partner_id, ref_id) else False

    def upload_to_s3_and_push_event(self, event, event_type, partner_info, application_id, body, request_reference_id):  # noqa: B950
        partner_id = partner_info.get('partner_uuid')

        key = f"{partner_id}/{application_id}/app_request/{request_reference_id}.json"  # noqa: B950
        version = self.s3.put_object(key, json.dumps(body))

        if not version:
            # Putting object into S3 failed
            return False

        details = {
            'metadata': {
                'traceparent': self.otel.traceparent()
            },
            'data': {
                'application_id': application_id,
                'partner_id': partner_id,
                'jwt': event.headers.get('jwt'),
                'request_uri': f"s3://{self.bucket()}/{key}#{version}"
            }
        }

        app.helpers.event_bridge.EventBridge().push_event(event_type, details)

        return True

    def validate_event_body(self, body, partner_id):
        profile = app.helpers.partner_profile.PartnerProfile(partner_id).profile()

        configured_services = set(profile.get('metadata', {}).get('services', []))
        requested_services = set(body.get('services', []))

        if len(requested_services) == 0:
            return False

        if not requested_services.issubset(configured_services):
            return False

        if 'verify' not in requested_services:
            return True

        configured_verifications = set(profile.get('stipulationVerificationConfig', {}).get('rules', {}).get('stipulations', {}).keys())  # noqa: B950
        requested_verifications = set(body.get('verifications', {}).keys())

        return requested_verifications.issubset(configured_verifications)

    def build_response(self, status_code, message):
        return {
            "status_code": status_code,
            "message": message
        }
