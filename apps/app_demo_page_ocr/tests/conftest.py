import os
import sys
from unittest.mock import mock_open, patch

from moto import mock_events, mock_s3
import pytest

sys.path.insert(0, '../src/app_demo_page_ocr')
MOCKED_ENV_VARS = {
    'LOG_LEVEL': 'INFO',
    'POWERTOOLS_METRICS_NAMESPACE': 'PageOCR',
    'GOOGLE_CLOUD_API_KEY': 'fake_key',
    'AWS_DEFAULT_REGION': 'us-west-2',
    'Environment': 'test'
}

os.environ = MOCKED_ENV_VARS  # noqa: B003


@pytest.fixture(autouse=True)
def default_mocks():
    with patch(
        'honeybadger.honeybadger.configure'
    ), patch(
        'honeybadger.honeybadger.notify'
    ), patch(
        'aws_lambda_powertools.Logger'
    ), patch(
        'aws_lambda_powertools.Metrics'
    ), patch(
        'libraries.s3.S3.download', return_value=None
    ), patch(
        'libraries.s3.S3.uri_for', return_value='s3://'
    ), patch(
        'libraries.s3.S3.put_object', return_value='1234'
    ), patch(
        'libraries.google_vision_api.GoogleVisionApi._get_image_content'
    ), patch(
        'cv2.cvtColor'
    ), patch(
        'handler.micro_angle', return_value=0
    ), patch(
        'handler.resize_image'
    ), patch(
        'builtins.open', mock_open(read_data='')
    ), patch(
        'PIL.Image.open'
    ) as mocked_pil, mock_s3(), mock_events():
        # mock dimensions for PIL Image
        mocked_pil.return_value.size = (100, 100)
        yield


@pytest.fixture(autouse=True)
def setup():
    # this mock is separate/not part of the defaults because I later want to mock it
    # on a case-by-case basis for better test coverage
    with patch(
        'libraries.lambdas.TextDetection.process', return_value={'driver_license_front': 1.0}  # noqa: B950
    ):
        yield
