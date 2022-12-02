import json
from unittest.mock import patch

from aws_lambda_powertools.utilities.validation.exceptions import \
    SchemaValidationError

from handler import handler
from libraries.google_vision_api import GoogleVisionApi

import pytest

from tests.event_helper import context, event_data

with open('ocr_response.json', 'r') as file:
    OCR_DATA = json.loads(file.read())

with open('aws_ocr_response.json', 'r') as file:
    AWS_OCR_DATA = json.loads(file.read())


def test_validation_empty_event_fails():
    with pytest.raises(SchemaValidationError):
        handler({}, {})


def test_validation_missing_file_id_fails():
    with pytest.raises(SchemaValidationError):
        handler(event_data(data_args={'resource_id': None}), {})


def test_validation_complete_event_passes():
    try:
        with patch('handler.package_data') as mocked, patch(
            'libraries.lambdas.TextractAnalysis.process',
            return_value=AWS_OCR_DATA
        ), patch(
            'libraries.google_vision_api.GoogleVisionRestClient.annotate',
            return_value=OCR_DATA
        ), patch('libraries.event_bridge.EventBridge.client.put_events',
                 side_effect=mocked_event_bridge_no_error):
            handler(event_data(), context())
            mocked.assert_called()
    except SchemaValidationError:
        raise AssertionError('Valid event raised an exception')


@patch('libraries.event_bridge.EventBridge.client.put_events')
def test_return_data_has_all_keys(_):
    try:
        with patch('handler.package_data') as mocked, patch(
            'libraries.lambdas.TextractAnalysis.process',
            return_value=AWS_OCR_DATA
        ), patch(
            'libraries.google_vision_api.GoogleVisionRestClient.annotate',
            return_value=OCR_DATA
        ):
            handler(event_data(), context())
            mocked.assert_called()

            data = mocked.call_args[0][0]
            assert 'ocr_data' in data
            assert 'dimensions' in data
    except SchemaValidationError:
        raise AssertionError('Valid event raised an exception')


def test_ocr_throws_non_200_error_still_sends_event():
    with patch(
        'libraries.event_bridge.EventBridge.client.put_events', side_effect=mocked_event_bridge_error  # noqa: B950
    ) as mocked, patch(
        'libraries.google_vision_api.GoogleVisionRestClient.annotate', side_effect=mocked_ocr  # noqa: B950
    ):
        handler(event_data(), context())
        mocked.assert_called()


def test_ocr_with_incoming_error_event_forwards_error():
    with patch(
        'libraries.event_bridge.EventBridge.client.put_events', side_effect=mocked_incoming_event_error  # noqa: B950
    ) as mocked, patch(
        'libraries.google_vision_api.GoogleVisionRestClient.annotate'  # noqa: B950
    ):
        handler(event_data(data_args={'error_message': 'DocumentService error message', 'page_uri': ''}), context())  # noqa: B950
        mocked.assert_called()


def test_ocr_has_all_keys():
    with patch(
            'libraries.google_vision_api.GoogleVisionRestClient.annotate',
            return_value=OCR_DATA
    ):
        results = GoogleVisionApi('fake_file').ocr_results()
        assert 'document_text' in results
        assert 'safe_search_annotation' in results
        assert 'full_text_annotation' not in results  # we are not using pages


def test_metadata_persists():
    with patch('handler.package_data') as mocked, patch(
        'libraries.lambdas.TextractAnalysis.process',
        return_value=AWS_OCR_DATA
    ), patch(
        'libraries.google_vision_api.GoogleVisionRestClient.annotate',
        return_value=OCR_DATA
    ), patch('libraries.event_bridge.EventBridge.client.put_events',
             side_effect=mocked_event_bridge_persists_metadata):
        handler(event_data(metadata_args={'internal_use': {'testing': {'test_application': True}}}), context())  # noqa: B950
        mocked.assert_called()


def mocked_event_bridge_no_error(*args, **kwargs):
    event = event_checker(*args, **kwargs)
    assert 'error_message' not in event['data']


def mocked_event_bridge_error(*args, **kwargs):
    event = event_checker(*args, **kwargs)
    assert 'error_message' in event['data']
    assert 'Google Cloud Vision returned non-200' in event['data']['error_message']


def mocked_incoming_event_error(*args, **kwargs):
    event = event_checker(*args, **kwargs)
    event_data = event['data']
    assert 'error_message' in event_data
    assert 'DocumentService error message' in event_data['error_message']
    assert event_data['data_uris'] == []
    assert event_data['page_uri'] == ''


def mocked_event_bridge_persists_metadata(*args, **kwargs):
    event = event_checker(*args, **kwargs)
    assert 'error_message' not in event['data']
    assert 'metadata' in event
    event_metadata = event['metadata']
    assert 'internal_use' in event_metadata
    assert 'testing' in event_metadata['internal_use']
    assert 'test_application' in event_metadata['internal_use']['testing']
    assert event_metadata['internal_use']['testing']['test_application'] is True


def event_checker(*args, **kwargs):
    assert len(kwargs['Entries']) == 1
    details = kwargs['Entries'][0]
    assert details['Source'] == 'pageOcr'
    assert details['DetailType'] == 'ImageProcessCompleted'
    return json.loads(details['Detail'])


def mocked_ocr(*args):
    raise RuntimeError('Google Cloud Vision returned non-200 status: 500 WITH BODY:!!')
