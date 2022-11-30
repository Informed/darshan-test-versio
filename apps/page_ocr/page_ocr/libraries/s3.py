import functools
import os
import tempfile

import boto3
from botocore.client import Config
from botocore.exceptions import ClientError
from helpers.setup_logging import SetupLogging
from honeybadger import honeybadger


class S3:
    FACTORY_CACHE = {}

    def __init__(self, bucket):
        self.log = SetupLogging()
        self.client = boto3.client('s3', config=Config(signature_version='s3v4'))
        self.bucket = bucket

    def env(self):
        return os.environ.get('Environment', 'qa')

    def region(self):
        return os.environ.get('AWS_REGION', '')

    @staticmethod
    def factory(bucket):
        if bucket in S3.FACTORY_CACHE:
            return S3.FACTORY_CACHE[bucket]

        S3.FACTORY_CACHE[bucket] = S3(bucket)
        return S3.FACTORY_CACHE[bucket]

    @staticmethod
    def factory_from_uri(uri):
        parts = S3.parts_from_uri(uri)
        return S3.factory(parts['bucket'])

    @staticmethod
    def download_uri(uri):
        parts = S3.parts_from_uri(uri)
        s3 = S3.factory(parts['bucket'])
        return s3.download(parts['key'], version=parts['version'])

    @staticmethod
    def put_uri(uri, content):
        parts = S3.parts_from_uri(uri)
        s3 = S3.factory(parts['bucket'])
        return s3.put_object(parts['key'], content)

    @staticmethod
    @functools.lru_cache(maxsize=10)  # LRU cache because we call this a lot
    def parts_from_uri(uri):
        parts = uri.split('s3://')[1].split('/', 1)
        bucket, key = parts
        version = None
        if '#' in key:
            key, version = key.split('#')
        return {'bucket': bucket, 'key': key, 'version': version}

    @staticmethod
    def key_from_uri(uri):
        parts = S3.parts_from_uri(uri)
        return parts['key']

    @staticmethod
    def generate_temp_file(filename):
        return os.path.join(tempfile.gettempdir(), filename)

    def download(self, file_name, version=None):
        try:
            temp_file_name = self.generate_temp_file(
                os.path.basename(file_name))
            self.client.download_file(self.bucket, file_name, temp_file_name,
                                      ExtraArgs={'VersionId': version})
            return temp_file_name
        except ClientError as e:
            honeybadger.notify(e, context={'file_name': file_name})
            self.log.info("Error downloading file: {} {}".format(file_name, e))
            raise e

    def uri_for(self, key, version):
        return f"s3://{self.bucket}/{key}#{version}"

    def put_object(self, key, content):
        self.log.info(
            f"Putting object into S3 bucket - {self.bucket} with path - {key}")
        response = self.client.put_object(
            Body=content,
            Bucket=self.bucket,
            Key=key
        )

        if response.get('ResponseMetadata', {}).get('HTTPStatusCode') != 200:
            honeybadger.notify(Exception('S3Error'), context={
                'message': 'S3 put object call failed',
                'request_id': response.get('ResponseMetadata', {}).get('RequestId'),
                'key': key
            })
            return None

        return response.get('VersionId')

    def generate_presigned_url(self, file_key, expiration=3600):
        self.log.info(f"Creating uploadUrl to - {self.bucket} with name - {file_key}")

        try:
            response = self.client.generate_presigned_url(
                ClientMethod='put_object',
                Params={'Bucket': self.bucket, 'Key': file_key},
                ExpiresIn=expiration
            )

        except ClientError as e:
            self.log.info('Client Generate Presigned Url Error!')
            honeybadger.notify(e, context={
                'file_key': file_key
            })
            # TODO: we can handle this more gracefully later
            return ''

        return response
