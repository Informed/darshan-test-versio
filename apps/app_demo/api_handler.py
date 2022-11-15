import html
import os
import traceback
from http import HTTPStatus

import simplejson as json
from aws_lambda_powertools.event_handler import Response, content_types
from aws_lambda_powertools.event_handler.api_gateway import \
    APIGatewayHttpResolver
from aws_lambda_powertools.event_handler.exceptions import (
    InternalServerError, NotFoundError, UnauthorizedError)
from honeybadger import honeybadger
from opentelemetry import trace
from opentelemetry.trace import (Link, NonRecordingSpan, SpanContext, SpanKind,
                                 TraceFlags)

import app.helpers.jwt
import app.helpers.setup_logging
from app.controllers.application_controller import ApplicationController
from app.controllers.documents_controller import DocumentsController
from app.controllers.edit_controller import EditController

# Anytime an exception is raised, it triggers a
# HoneyBadger in app_demo project
honeybadger.configure(
    api_key=os.environ.get('HONEYBADGER_API_KEY'),
    environment=os.environ.get('HONEYBADGER_ENVIRONMENT'),
    force_report_data=os.environ.get('HONEYBADGER_FORCE_REPORT_DATA', 'true')
)

# Get a tracer from the Global Tracer Provider
tracer = trace.get_tracer(__name__)


def custom_serializer(response):
    return json.dumps(response)


router = APIGatewayHttpResolver(serializer=custom_serializer)


@router.get('/<version>/auto/applications')
def get_applications(version):
    response = ApplicationController(router.current_event, version).get_applications()

    return render_response(response, 'payload')


# Create a new application
@router.post('/<version>/auto/applications')
def post_applications(version):
    response = ApplicationController(router.current_event, version).create_application()

    return render_response(response)


# Update an existing application
@router.put('/<version>/auto/applications/<application_id>')
def put_applications(version, application_id):
    application_id = html.escape(application_id)
    response = ApplicationController(router.current_event, version).update_application(application_id)  # noqa: B950

    return render_response(response)


# Get an existing application
@router.get('/<version>/auto/applications/<application_id>')
def get_application(version, application_id):
    application_id = html.escape(application_id)
    response = ApplicationController(router.current_event, version).get_application(application_id)  # noqa: B950

    return render_response(response, 'payload')


# Upload url to upload documents
@router.post('/<version>/auto/applications/<application_id>/documents')
def post_documents_upload(version, application_id):
    application_id = html.escape(application_id)
    response = DocumentsController(router.current_event, version).create_documents_upload_urls(application_id)  # noqa: B950

    return render_response(response)


# Get documents of an application
@router.get('/<version>/auto/applications/<application_id>/documents')
def get_documents(version, application_id):
    application_id = html.escape(application_id)
    response = DocumentsController(router.current_event, version).get_documents(application_id)  # noqa: B950

    return render_response(response, 'payload')


# Edit extracted_data
@router.put('/<version>/auto/applications/<application_id>/documents/<document_id>')
def post_edits(version, application_id, document_id):
    app_id = html.escape(application_id)
    doc_id = html.escape(document_id)
    response = EditController(router.current_event, version).document(app_id, doc_id)

    return render_response(response)


# Catch any other route that is not defined
@router.get(".+")
def catch_any_route_after_any():
    return {'message': 'Invalid request: path not available!'}


def render_response(response, key=None):
    if response.get('status_code') == 404:
        raise NotFoundError
    elif response.get('status_code') == 400:
        return Response(
            status_code=HTTPStatus.BAD_REQUEST.value,
            body=json.dumps(response),
            content_type=content_types.APPLICATION_JSON
        )
    elif response.get('status_code') == 500:
        raise InternalServerError(response)
    elif key:
        return response.get(key)
    return response


# Validate JWT
def validate_jwt(headers, raw_path):
    valid, partner_info = app.helpers.jwt.Jwt().validate_jwt(headers.get('jwt'), raw_path)  # noqa: B950
    if not valid:
        raise ValueError

    return partner_info


def handler(event, context):
    # Start of the service
    # All paths and events to the api handler will go through this function
    # The structure of the event must follow this convention
    # https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-lambda-authorizer.html#http-api-lambda-authorizer.payload-format

    # Based on the rawPath, the router will route
    # the request to it's respective controller

    # For more information on router, refer to the
    # aws_lambda_powertools.event_handler.api_gateway library

    # Get current span context
    current_span_context = trace.get_current_span().get_span_context()

    # Extract trace context from event
    trace_context = get_parent_context(event.get('headers', {}).get('traceparent'))

    # Create a new span, passing extracted context as a parent.
    # This is the way to "continue" the original trace for the message.
    with tracer.start_as_current_span(
        'app_demo',                # name of the span
        context=trace_context,               # context of the parent span
        kind=SpanKind.SERVER,                # kind of the span
        links=[Link(current_span_context)],  # links to other spans
        attributes=span_attributes(event)
    ) as span:
        # Start of the service
        span.add_event('Start of Api Handler lambda')
        try:
            # Validate the jwt to fetch partner info
            event['partner_info'] = validate_jwt(
                event.get('headers'), event.get('rawPath')
            )

            # Api Gateway Http Resolver
            return router.resolve(event, context)
        except ValueError as e:
            honeybadger.notify(e, context={
                'raw_path': event.get('rawPath', None),
                'message': 'Invalid JWT'
            })

            raise UnauthorizedError('Invalid authorization!')
        except Exception as e:
            honeybadger.notify(e, context={
                'raw_path': event.get('rawPath', None),
                'error_info': repr(e),
                'traceback': traceback.print_exc()
            })

            return {
                'status_code': 500,
                'body': json.dumps({'message': 'Something went wrong :('})
            }


def span_attributes(event):
    return {
        'app_demo.request.type': event.get('type'),
        'app_demo.request.path': event.get('rawPath')
    }


def get_parent_context(traceparent):
    version, trace_id, span_id, trace_flags = traceparent.split(',')[-1].split('-')

    parent_context = SpanContext(
        trace_id=int(trace_id, 16),
        span_id=int(span_id, 16),
        is_remote=True,
        trace_flags=TraceFlags(int(trace_flags, 16))
    )
    return trace.set_span_in_context(NonRecordingSpan(parent_context))
