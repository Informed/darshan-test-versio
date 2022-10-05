import app.controllers.admin
import app.controllers.partner_profile
import app.helpers.setup_logging

from aws_lambda_powertools.event_handler.api_gateway import APIGatewayHttpResolver
from aws_lambda_powertools.event_handler.exceptions import (
    BadRequestError, InternalServerError, NotFoundError
)
from honeybadger import honeybadger
from opentelemetry import trace
from opentelemetry.trace import NonRecordingSpan, SpanContext, SpanKind, TraceFlags, Link

import os
import re
import simplejson as json
import traceback

# Anytime an exception is raised, it triggers a
# HoneyBadger in partner_authorizer project
honeybadger.configure(
    api_key=os.environ.get('HONEYBADGER_API_KEY', ''),
    environment=os.environ.get('HONEYBADGER_ENVIRONMENT', ''),
    force_report_data=os.environ.get('HONEYBADGER_FORCE_REPORT_DATA', 'true')
)

# Get a tracer from the Global Tracer Provider
tracer = trace.get_tracer(__name__)

UUID_REGEX = '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'


def custom_serializer(response):
    return json.dumps(response)


router = APIGatewayHttpResolver(serializer=custom_serializer)


# Get complete partner profile by partner name
@router.get('/v1/partner_profile/name/<partner_name>')
def get_partner_profile_name(partner_name):
    response = app.controllers.partner_profile.PartnerProfile() \
                  .complete_profile_from_name(partner_name)

    return render_response(response)


# Get service profile by partner name
@router.get('/v1/partner_profile/name/<partner_name>/services/<service_name>')
def get_partner_profile_service(partner_name, service_name):
    response = app.controllers.partner_profile.PartnerProfile() \
                  .service_profile_from_name(partner_name, service_name)

    return render_response(response)


# Get email's projected attributes
@router.get('/v1/partner_profile/email/<email>')
def get_partner_profile_email(email):
    response = app.controllers.partner_profile.PartnerProfile() \
                  .partner_from_query_params({'email': email})

    return render_response(response)


# Get subdomain projected attributes using query parameters
@router.get('/v1/partner_profile')
def get_partner_profile_subdomain():
    query_strings_as_dict = router.current_event.query_string_parameters
    response = app.controllers.partner_profile.PartnerProfile() \
                  .partner_from_query_params(query_strings_as_dict)

    return render_response(response)


# Create a new partner profile
@router.post('/v1/partner_profiles')
def post_partner_profiles():
    response = app.controllers.partner_profile.PartnerProfile() \
                  .create_profile(router.current_event)

    return render_response(response)


# Update an existing partner profile
@router.put('/v1/partner_profiles/<uuid>')
def put_partner_profiles(uuid):
    if not re.search(UUID_REGEX, uuid):
        raise BadRequestError('Invalid UUID!')

    response = app.controllers.partner_profile.PartnerProfile() \
                  .update_profile(router.current_event)

    return render_response(response)


# Get complete partner profile by partner uuid
@router.get('/v1/partner_profiles/<uuid>')
def get_partner_profiles_uuid(uuid):
    if not re.search(UUID_REGEX, uuid):
        raise BadRequestError('Invalid UUID!')

    response = app.controllers.partner_profile.PartnerProfile() \
                              .complete_profile_from_id(uuid)

    return render_response(response)


# Get service profile by partner uuid
@router.get('/v1/partner_profiles/<uuid>/services/<service_name>')
def get_partner_profiles_service(uuid, service_name):
    if not re.search(UUID_REGEX, uuid):
        return {'success': False, 'message': 'Invalid UUID'}

    response = app.controllers.partner_profile.PartnerProfile() \
                  .service_profile_from_id(uuid, service_name)

    return render_response(response)


# Get the service of all partner profiles using query parameters
@router.get('/v1/partner_profiles')
def get_partner_profiles_service_list():
    query_strings_as_dict = router.current_event.query_string_parameters
    response = app.controllers.partner_profile.PartnerProfile() \
                  .partners_from_query_params(query_strings_as_dict)

    return render_response(response, 'items')


# Perform health check on partner profile service
@router.get('.+/partner_profile/health_check')
def perform_health_check():
    response = app.controllers.partner_profile.PartnerProfile() \
                  .health_check_partner_profile()

    return render_response(response)


# Catch any other route that is not defined
@router.get(".+")
def catch_any_route_after_any():
    return {'success': False, 'message': 'Invalid request: path not available!'}


def render_response(response, key=None):
    if response.get('statusCode') == 404:
        raise NotFoundError
    elif response.get('statusCode') == 400:
        raise BadRequestError(response.get('message'))
    elif response.get('statusCode') == 500:
        raise InternalServerError(response)
    elif key:
        return response.get(key)
    return response


def handler(event, context):
    # Get current span context
    current_span_context = trace.get_current_span().get_span_context()

    # Extract trace context from event
    trace_context = get_parent_context(event)

    # Create a new span, passing extracted context as a parent.
    # This is the way to "continue" the original trace for the message.
    with tracer.start_as_current_span(
        'partner_profile',                    # name of the span
        context=trace_context,               # context of the parent span
        kind=SpanKind.SERVER,                # kind of the span
        links=[Link(current_span_context)],  # links to other spans
        attributes=span_attributes(event)
    ) as span:
        # Start of the service
        span.add_event('Start of Partner Profile lambda')
        try:
            # Direct lambda invocation
            if event.get('type') == 'PARTNER_AUTHORIZER':
                return app.controllers.admin.Admin().profile_admin_creds(event)
            # Api Gateway Http Resolver
            else:
                return router.resolve(event, context)
        except Exception as e:
            honeybadger.notify(e, context={
                'raw_path': event.get('rawPath', None),
                'source': event.get('source', None),
                'error_info': repr(e),
                'traceback': traceback.print_exc()
            })

            return {
                'statusCode': 500,
                'body': json.dumps({'success': False, 'message': 'Something went wrong :('})
            }


def span_attributes(event):
    return {
        'partner_profile.request.type': event.get('type'),
        'partner_profile.request.path': event.get('rawPath')
    }


def get_parent_context(event):
    traceparent = event.get('headers', {}).get('traceparent')
    if not traceparent:
        traceparent = event.get('requestContext', {}).get('authorizer', {}) \
                           .get('lambda', {}).get('traceparent', '')

    version, trace_id, span_id, trace_flags = traceparent.split('-')

    parent_context = SpanContext(
        trace_id=int(trace_id, 16),
        span_id=int(span_id, 16),
        is_remote=True,
        trace_flags=TraceFlags(int(trace_flags, 16))
    )
    return trace.set_span_in_context(NonRecordingSpan(parent_context))
