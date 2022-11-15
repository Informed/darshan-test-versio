import json
import os
import app.api_validation.api_validator
import pytest

TEST_FILES = ['expected.json', 'partner_profile.json', 'request_body.json']


class TestApiValidation:
    def build_parameters():
        parameters = []
        unit_tests_file_path = 'api_validation'
        # Get the list of all directories in 'unit_tests/api_validation' in alphanumeric order
        for test_suite in sorted(os.listdir(unit_tests_file_path)):
            test_data = {}
            # Load config, expected, partner_profile, request_body into test_data
            path = os.path.join(unit_tests_file_path, test_suite)
            test_data['config'] = os.path.join(path, 'config.yml')
            for file_name in TEST_FILES:
                with open(os.path.join(path, file_name)) as f:
                    test_data[file_name.split('.')[0]] = json.load(f)
            parameters.append((test_data['config'], test_data['request_body'], test_data['partner_profile'], test_data['expected']))  # noqa: B950
        return parameters

    # Dynamically run each test case as its own Pytest function
    @pytest.mark.parametrize("config, request_body, partner_profile, expected", build_parameters())   # noqa: B950
    def test_api_validator(self, config, request_body, partner_profile, expected):
        errors = app.api_validation.api_validator.validate_request(config, request_body, partner_profile)   # noqa: B950
        assert errors == expected['errors']
