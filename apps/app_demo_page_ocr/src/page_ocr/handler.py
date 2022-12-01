# Input event structure
# {
#     "partner_id": "partner_id",
#     "application_id": "application_id",
#     "resource_id": "resource_id",
#     "resource_type": "resource_type",
#     "page_number": "page_number",
#     "total_pages": "total_pages",
#     "page_uri": "s3_path#version"
# }

# Output event structure
# {
#     "partner_id": "partner_id",
#     "application_id": "application_id",
#     "resource_id": "resource_id",
#     "resource_type": "resource_type",
#     "page_number": "page_number",
#     "total_pages": "total_pages",
#     "page_uri": "s3_path#version",
#     "data_uris": [
#         {
#             "source": "google",
#             "ocr_data_uri": "s3_path#version"
#         },
#         {
#             "source": "aws",
#             "ocr_data_uri": "s3_path#version"
#         }
#     ]
# }

import json
import os

from PIL import Image as PIL_Image
from aws_lambda_powertools import Logger, Metrics
from aws_lambda_powertools.utilities.data_classes import EventBridgeEvent
from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.utilities.validation import envelopes, validator
from honeybadger import honeybadger

from libraries.event_bridge import EventBridge
from libraries.google_vision_api import TEXT
from libraries.s3 import S3

from schemas import image_process_start as schema
from utils.image import (convert_pil_image_to_cv2, macro_angle, micro_angle,
                         resize_image, rotate_image)
from utils.metrics.default_dimensions import DefaultDimensions
from utils.metrics.metrics import HISTOGRAM, MetricWrapper
from utils.ocr import run_aws_ocr, run_google_ocr, should_run_text_detection, text, words

# Anytime an exception is raised, it triggers a
# HoneyBadger in app_demo_page_ocr project
honeybadger.configure(api_key=os.environ.get('HONEYBADGER_API_KEY'),
                      environment=os.environ.get('HONEYBADGER_ENVIRONMENT'),
                      force_report_data=os.environ.get(
                          'HONEYBADGER_FORCE_REPORT_DATA', 'true'))

logger = Logger()
metrics = Metrics()

GOOGLE_OCR_RUN = 'GoogleOCRRun'
AWS_OCR_RUN = 'AWSOCRRun'


def package_data(data):
    return json.dumps(data)


def rotate_image_if_needed(file_name, words):
    # given the preliminary ocr result, we want to detect "macro" angles of rotation
    # we use the bounds provided by ocr to do this, and then correct the rotation on
    # a macro scale
    # then we use opencv to detect smaller angles and further correct the rotation
    angle = macro_angle(words)
    rotated = False
    with PIL_Image.open(file_name) as image:
        rotated_image = None
        if angle != 0:
            rotated_image = rotate_image(image, -1 * angle)
        if rotated_image is None:
            rotated_image = image
        small_angle = micro_angle(convert_pil_image_to_cv2(rotated_image))
        rotation_angle = (-1 * angle) + small_angle
        if rotation_angle != 0:
            image = rotate_image(image, rotation_angle)
            rotated = True
        image = resize_image(image)
        image = image.convert('RGB')
        fmt = image.format if image.format in ['JPEG', 'PNG'] else 'JPEG'
        image.save(file_name, fmt)  # save image to disk so we can pull ocr

    return rotated


@metrics.log_metrics(capture_cold_start_metric=True)
@validator(inbound_schema=schema.IMAGE_PROCESS_START,
           envelope=envelopes.EVENTBRIDGE)
@logger.inject_lambda_context(log_event=True)
def handler(event: EventBridgeEvent, context: LambdaContext):
    file_name = None  # predefine this variable for cleanup later on
    error = None  # for final consolidation when putting together event details
    try:
        event_data = event['data']
        partner_id = event_data['partner_id']
        application_id = event_data['application_id']
        resource_id = event_data['resource_id']
        resource_type = event_data['resource_type']
        page_uri = event_data['page_uri']
        error = event_data['error_message'] if 'error_message' in event_data else None
        try:
            test_app = event['metadata']['internal_use']['testing']['test_application']
        except BaseException:
            test_app = False

        DefaultDimensions.clear()
        DefaultDimensions.set({
            'partner_id': partner_id,
            'env': os.environ.get('Environment'),
            'test_app': test_app
        })
        metric_wrapper = MetricWrapper(DefaultDimensions.get())
        metric_wrapper.track_request_received()
        metric_wrapper.timer_start('ExecutionTime')

        if not error:
            file_name = S3.download_uri(page_uri)
            s3 = S3.factory_from_uri(page_uri)
            page_fn = S3.key_from_uri(page_uri).split('/')[-1]
            directory = 'file' if resource_type == 'file' else 'documents'
            page_key_prefix = f"{partner_id}/{application_id}/{directory}/{resource_id}/ocr/{os.path.splitext(page_fn)[0]}"  # noqa: B950

            ocr_result = run_google_ocr(file_name,
                                        metric_wrapper,
                                        post_rotation=False)

            run_ocr_again = rotate_image_if_needed(file_name, words(ocr_result))
            if run_ocr_again:
                ocr_result = run_google_ocr(file_name, metric_wrapper)

            # for certain document types, we want to run an additional type of OCR called
            # TEXT_DETECTION. This typically works better on images, like driver licenses,
            # than the default DOCUMENT_TEXT_DETECTION
            # since we don't know what the document type is at this stage, we have a
            # specialized model for determining whether or not we should call TEXT_DETECTION
            if should_run_text_detection(text(ocr_result)):
                text_result = run_google_ocr(file_name,
                                             metric_wrapper,
                                             features=[TEXT],
                                             post_rotation=run_ocr_again)
                if text_result is not None:
                    ocr_result = text_result if ocr_result is None else {
                        **ocr_result,
                        **text_result
                    }

            google_data = {}  # initialize return data
            google_data['ocr_data'] = ocr_result

            # upload final page image to s3 and then grab the dimensions for the image since
            # we have it open
            dimensions = {}
            with open(file_name, 'rb') as image:
                image_version = S3.put_uri(page_uri, image)
                img = PIL_Image.open(image)
                width, height = img.size
                dimensions = {'height': height, 'width': width}

            aws_data = {}
            aws_data['ocr_data'] = run_aws_ocr(page_uri, metric_wrapper)

            google_data['dimensions'] = dimensions
            aws_data['dimensions'] = dimensions

            # store page ocr data in s3
            google_page_key = f"{page_key_prefix}.json"
            google_ocr_version = s3.put_object(google_page_key, package_data(google_data))
            aws_page_key = f"{page_key_prefix}-AWS.json"
            aws_ocr_version = s3.put_object(aws_page_key, package_data(aws_data))
    except BaseException as e:
        error = str(e)
        honeybadger.notify(e, context=event)
        logger.exception(e)
        metric_wrapper.error()
    finally:
        # delete the downloaded file, this lambda may be reused and we don't want to
        # run out of disk space
        if file_name is not None and os.path.exists(file_name):
            os.remove(file_name)

        details = {
            'partner_id': partner_id,
            'application_id': application_id,
            'resource_id': resource_id,
            'resource_type': resource_type,
            'page_number': event_data.get('page_number'),
            'total_pages': event_data.get('total_pages'),
            'job_id': event_data.get('job_id')
        }
        if error is None:
            details['page_uri'] = s3.uri_for(S3.key_from_uri(page_uri),
                                             image_version)
            details['data_uris'] = [{
                'source':
                'google',
                'ocr_data_uri':
                s3.uri_for(google_page_key, google_ocr_version)
            }, {
                'source':
                'aws',
                'ocr_data_uri':
                s3.uri_for(aws_page_key, aws_ocr_version)
            }]
        else:
            details['data_uris'] = []
            details['page_uri'] = event_data.get('page_uri')
            details['error_message'] = error

        EventBridge.push_event('ImageProcessCompleted', {
            'metadata': event['metadata'],
            'data': details
        })
        metric_wrapper.timer_stop('ExecutionTime', metric_type=HISTOGRAM)
