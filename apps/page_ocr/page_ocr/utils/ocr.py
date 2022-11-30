from libraries.google_vision_api import (DOCUMENT_TEXT, GoogleVisionApi, SAFE_SEARCH)
from libraries.lambdas import TextDetection, TextractAnalysis

from page_ocr.utils.metrics.default_dimensions import DefaultDimensions
from page_ocr.utils.metrics.metrics import MetricWrapper

TEXT_DETECTION_DOC_TYPES = set(['form_1040'])
OCR_RUN = 'OCRRun'
TEXT_DETECTION_CHECK = 'TextDetectionCheck'


def run_google_ocr(file_name, metric_wrapper, features=(DOCUMENT_TEXT, SAFE_SEARCH),
                   post_rotation=True):
    ocr_result = GoogleVisionApi(file_name=file_name, feature_types=features).ocr_results()
    metric_wrapper.count(OCR_RUN, dimensions={
        'source': 'google',
        'features': features[0],
        'post_rotation': post_rotation
    })
    return ocr_result


def run_aws_ocr(page_uri, metric_wrapper):
    ocr_result = TextractAnalysis.process(page_uri)['ocr']
    metric_wrapper.count(OCR_RUN, dimensions={
        'source': 'aws',
        'features': 'OCR'
    })
    return ocr_result


def should_run_text_detection(text):
    result = TextDetection.process(text)

    if result is None:
        return False

    # we receive a map of probabilities of doc types, and we want to get the one with
    # the highest probability. If that type is one in our list, we run text detection
    max_key = max(result, key=result.get)
    should_run = max_key in TEXT_DETECTION_DOC_TYPES
    if should_run:
        MetricWrapper(DefaultDimensions.get()).count(TEXT_DETECTION_CHECK, dimensions={
            'document_type': max_key
        })
    return should_run


def words(ocr_result):
    # we are only looking at the 1st element forward because the 0th element is the
    # complete, combined "text" of the response, not an individual word
    if DOCUMENT_TEXT in ocr_result and len(ocr_result[DOCUMENT_TEXT]) > 1:
        return ocr_result[DOCUMENT_TEXT][1:]
    else:
        return []


def text(ocr_result):
    # the first element in this array is the complete, combined "text" of the reponse
    if DOCUMENT_TEXT in ocr_result and len(ocr_result[DOCUMENT_TEXT]) > 0:
        return ocr_result[DOCUMENT_TEXT][0].get('description', '')
    else:
        return ''
