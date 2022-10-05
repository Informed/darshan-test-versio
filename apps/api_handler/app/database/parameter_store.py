import app.helpers.setup_logging

from honeybadger import honeybadger

import boto3
import os


class ParameterStore:
    def __init__(self):
        self.log = app.helpers.setup_logging.SetupLogging()
        self.ssm = boto3.client('ssm', region_name=os.environ.get('AWS_REGION'))

    def get(self, path):
        self.log.info(f"Getting object from Parameter Store with path - {path}")
        try:
            if not path:
                return None

            response = self.ssm.get_parameter(Name=path, WithDecryption=True)
            if response.get('ResponseMetadata', {}).get('HTTPStatusCode') != 200:
                raise Exception('Parameter Store Fetch Failed!')

            self.log.info('Parameter Store Fetch Successful!')
            return response.get('Parameter', {}).get('Value')
        except Exception as e:
            self.log.info('Parameter Store Fetch Failed!')
            honeybadger.notify(e, context={
                'path': path
            })

            return None
