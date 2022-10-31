import unittest
import app.helpers.response_builder
import json


class TestResponseHandler(unittest.TestCase):
    def test_data_sources_with_old_stipulation_format(self):
        with open('test_files/old_stipulation_json_format.json') as f:
            test_parameters = json.load(f)
        verification_response = app.helpers.response_builder.ResponseBuilder.stipulation_response(test_parameters, 'app_id', 'app_ref_id')  # noqa: B950
        self.assertEqual(list(verification_response.keys()), ['event_type', 'application_id', 'application_reference_id', 'verifications'])  # noqa: B950
        self.assertTrue('data_sources' not in list(verification_response.keys()))

    def test_data_sources_with_new_stipulation_format(self):
        with open('test_files/new_stipulation_json_format.json') as f:
            test_parameters = json.load(f)
        verification_response = app.helpers.response_builder.ResponseBuilder.stipulation_response(test_parameters, 'app_id', 'app_ref_id')  # noqa: B950
        self.assertTrue('data_sources' in list(verification_response.keys()))
        data_sources = verification_response['data_sources']
        self.assertTrue('image_files' in list(data_sources.keys()))
        self.assertTrue('structured_data' in list(data_sources.keys()))
        self.assertEqual(data_sources['image_files'], [{"file_id": "file_id_1", "file_reference_id": "file_reference_id_1"}])  # noqa: B950
        self.assertEqual(data_sources['structured_data'], [{"document_id": "document_id_1", "document_reference_id": "document_reference_id_1"}])  # noqa: B950
