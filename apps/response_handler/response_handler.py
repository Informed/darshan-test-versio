# from operator import truediv
# from turtle import end_fill
import app.helpers.jwt
from app.helpers.setup_logging import log

from honeybadger import honeybadger
# from opentelemetry import trace
# from opentelemetry.trace import NonRecordingSpan, SpanContext, TraceFlags
import app.controllers.webhook

import os
import simplejson as json
import traceback

# Anytime an exception is raised, it triggers a
# HoneyBadger in response_handler project
honeybadger.configure(
    api_key=os.environ.get('HONEYBADGER_API_KEY'),
    environment=os.environ.get('HONEYBADGER_ENVIRONMENT'),
    force_report_data=os.environ.get('HONEYBADGER_FORCE_REPORT_DATA', 'true')
)

# Get a tracer from the Global Tracer Provider
# tracer = trace.get_tracer(__name__)


# Validate JWT
# TODO: check where is jwt present in the event
def validate_jwt(encoded_jwt, event_type):
    # valid = app.helpers.jwt.Jwt().validate_jwt(encoded_jwt, event_type)
    # if not valid:
    #     raise ValueError
    # return valid
    # TODO: uncomment validation when jwt is linked
    return True


def handler(event, context):
    # Start of the service

    # Get current span context
    # current_span_context = trace.get_current_span().get_span_context()

    # Extract trace context from event
    # TODO: Uncomment this code when OpenTelemetry is ready
    # TODO: check where is traceparent present in the event
    # trace_context = get_parent_context(event)

    # Create a new span, passing extracted context as a parent.
    # This is the way to "continue" the original trace for the message.
    # with tracer.start_as_current_span(
    #     'response_handler',                # name of the span
    #     context=trace_context,               # context of the parent span
    #     kind=SpanKind.SERVER,                # kind of the span
    #     links=[Link(current_span_context)],  # links to other spans
    #     attributes=span_attributes(event)
    # ) as span:
    # Start of the service
    # span.add_event('Start of Response Handler lambda')
    log.info('Response Handler: start handling')
    try:
        # Validate the jwt to fetch partner info
        validate_jwt(
            event.get('headers'), event.get('rawPath')
        )
        # TODO: process the event
        response = {}
        if event['detail-type'] == 'DocumentsExtractionComplete':
            response = app.controllers.webhook.Webhook() \
                .extraction(event)
        elif event['detail-type'] == 'StipulationVerificationComplete':
            response = app.controllers.webhook.Webhook() \
                .verification(event)
        return response
    except ValueError as e:
        log.info('Response Handler: Invalid JWT')
        honeybadger.notify(e, context={
            'event_type': event.get('type'),
            'event_source': event.get('source'),
            'message': 'Invalid JWT'
        })

        return {
            'status_code': 500,
            'body': json.dumps({'message': 'Something went wrong :('})
        }
    except Exception as e:
        log.info('Response Handler: something went wrong')
        honeybadger.notify(e, context={
            'event_type': event.get('type'),
            'event_source': event.get('source'),
            'error_info': repr(e),
            'traceback': traceback.print_exc()
        })

        return {
            'status_code': 500,
            'body': json.dumps({'message': 'Something went wrong :('})
        }


# def span_attributes(event):
#     # TODO: update attributes according to the event structure
#     return {
#         'response_handler.event.type': event.get('type'),
#         'response_handler.event.source': event.get('source')
#     }


# def get_parent_context(traceparent):
#     version, trace_id, span_id, trace_flags = traceparent.split('-')

#     parent_context = SpanContext(
#         trace_id=int(trace_id, 16),
#         span_id=int(span_id, 16),
#         is_remote=True,
#         trace_flags=TraceFlags(int(trace_flags, 16))
#     )
#     return trace.set_span_in_context(NonRecordingSpan(parent_context))
