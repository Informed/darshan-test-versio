from app.helpers.setup_logging import log

from honeybadger import honeybadger

import boto3
import os
from botocore.exceptions import ClientError


class S3:
    def __init__(self, bucket):
        self.client = boto3.client('s3')
        self.bucket = bucket

    def env(self):
        return os.environ.get('Environment', 'qa')

    def region(self):
        return os.environ.get('AWS_REGION', '')

    def put_object(self, key, content):
        log.info(f"Putting object into S3 bucket - {self.bucket} with path - {key}")
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

    def get_object(self, key, version=None):
        log.info(f"Getting object from S3 bucket - {self.bucket} with path - {key} - version {version}")  # noqa: B950
        response = self.client.get_object(
            Bucket=self.bucket,
            Key=key
        ) if version is None else self.client.get_object(
            Bucket=self.bucket,
            Key=key,
            VersionId=version
        )
        if response.get('ResponseMetadata', {}).get('HTTPStatusCode') != 200:
            honeybadger.notify(Exception('S3Error'), context={
                'message': 'S3 get object call failed',
                'request_id': response.get('ResponseMetadata', {}).get('RequestId'),
                'key': key
            })
            return None
        log.info(f"Response: {response}")
        return response["Body"].read().decode()

    def generate_presigned_url(self, file_key, expiration=3600):
        log.info(f"Creating uploadUrl to - {self.bucket} with name - {file_key}")

        try:
            response = self.client.generate_presigned_url(
                ClientMethod='get_object',
                Params={'Bucket': self.bucket, 'Key': file_key},
                ExpiresIn=expiration
            )

        except ClientError as e:
            log.info('Client Generate Presigned Url Error!')
            honeybadger.notify(e, context={
                'file_key': file_key
            })
            # TODO: we can handle this more gracefully later
            return ''

        return response
