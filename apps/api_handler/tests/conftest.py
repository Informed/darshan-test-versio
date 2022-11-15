import os

MOCKED_ENV_VARS = {
    'LOG_LEVEL': 'INFO',
    'AWS_DEFAULT_REGION': 'us-west-2'
}

os.environ = MOCKED_ENV_VARS  # noqa: B003
# just adding api_handler to get an accurate picture of code coverage
import api_handler  # noqa: F401 E402
