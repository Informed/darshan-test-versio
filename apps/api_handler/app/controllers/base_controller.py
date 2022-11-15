import html
import os

from app.database.s3 import S3
from app.helpers.recorder import Recorder
from app.helpers.setup_logging import log


class BaseController:
    def __init__(self, event, version):
        self.event = event
        self.version = html.escape(version)
        self.log = log
        self.recorder = Recorder()
        self.s3 = S3(self.bucket())
        self.setup()

    # Anything else you want set up, override this method and add it here
    def setup(self):
        pass

    def env(self):
        return os.environ.get('Environment', 'qa')

    def bucket(self):
        return os.environ.get('AWS_DEFAULT_BUCKET')

    def build_response(self, status_code, message):
        return {
            "status_code": status_code,
            "message": message
        }
