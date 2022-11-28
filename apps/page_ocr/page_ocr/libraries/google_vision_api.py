import base64
import os

import humps
import requests

from utils.metrics.default_dimensions import DefaultDimensions
from utils.metrics.metrics import MetricWrapper

DOCUMENT_TEXT = 'document_text'
SAFE_SEARCH = 'safe_search'
TEXT = 'text'
TEXT_ANNOTATIONS = 'text_annotations'
FULL_TEXT_ANNOTATION = 'full_text_annotation'


class GoogleVisionRestClient:
    def __init__(self):
        api_key = os.environ['GOOGLE_CLOUD_API_KEY']
        self.url = f"https://us-vision.googleapis.com/v1/images:annotate?key={api_key}"
        self.metric_wrapper = MetricWrapper(DefaultDimensions.get())

    def annotate(self, request):
        formatted = {
            'requests': [request]
        }
        with self.metric_wrapper.timer('GoogleOCRRunDuration'):
            response = requests.post(self.url, json=formatted)

        self.metric_wrapper.count('GoogleOCRResponseStatus', dimensions={'status': response.status_code})  # noqa: B950

        if response.ok:
            resp = response.json()['responses']
            return humps.decamelize(resp[0])
        else:
            raise RuntimeError(
                f"Google Cloud Vision returned non-200 status: {str(response.status_code)} WITH BODY: {response.text}")  # noqa: B950


class GoogleVisionApi:
    FEATURE_TYPES_MAPPING_REST = {
        TEXT: 'TEXT_DETECTION',
        DOCUMENT_TEXT: 'DOCUMENT_TEXT_DETECTION',
        SAFE_SEARCH: 'SAFE_SEARCH_DETECTION'
    }

    DEFAULT_FEATURE_TYPES = list(FEATURE_TYPES_MAPPING_REST.keys())

    def __init__(self, file_name, feature_types=DEFAULT_FEATURE_TYPES):
        self.file_name = file_name
        feature_types = feature_types or self.DEFAULT_FEATURE_TYPES
        self.features = list(set(self.DEFAULT_FEATURE_TYPES) & set(feature_types))
        self.text_response = None
        if self._text_and_doc_text_present():
            self.text_response = self._annotate(['text'])
        self.response = self._annotate(self.features)

    def _text_and_doc_text_present(self):
        return TEXT in self.features and DOCUMENT_TEXT in self.features

    def _get_image_content(self):
        if self.file_name:
            with open(self.file_name, 'rb') as f:
                encoded_str = f.read()
                return {'content': base64.b64encode(encoded_str).decode('ascii')}
        else:
            return {'source': {'image_uri': self.file_url}}

    def _annotate(self, given_features):
        features = [{'type': self.FEATURE_TYPES_MAPPING_REST[t]}
                    for t in given_features]
        image_content = self._get_image_content()
        req = {
            'image': image_content,
            'features': features,
            'image_context': {'language_hints': ['en']}
        }
        response = GoogleVisionRestClient().annotate(req)
        return response

    def ocr_results(self):
        if TEXT_ANNOTATIONS in self.response:
            if self._text_and_doc_text_present():
                self._set_text_node(
                    DOCUMENT_TEXT, self.response.get(TEXT_ANNOTATIONS, {}))
                self._set_text_node(
                    TEXT, self.text_response.get(TEXT_ANNOTATIONS, {}))
            elif TEXT in self.features:
                self._set_text_node(
                    TEXT, self.response.get(TEXT_ANNOTATIONS, {}))
            else:
                self._set_text_node(
                    DOCUMENT_TEXT, self.response.get(TEXT_ANNOTATIONS, {}))
            self.response.pop(TEXT_ANNOTATIONS)
            self.response.pop(FULL_TEXT_ANNOTATION)

        return self.response

    def _set_text_node(self, typpe, text):
        self.response[typpe] = text
