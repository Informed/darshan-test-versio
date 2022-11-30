import json
import os
from urllib.parse import urlparse

import boto3
from honeybadger import honeybadger


class Lambda:
    def __init__(self, function_name):
        self.client = boto3.client('lambda')
        self.function = f"informed-{os.environ['Environment']}-{function_name}"

    def _process(self, payload):
        try:
            response = self.client.invoke(
                FunctionName=self.function,
                InvocationType='RequestResponse',
                Payload=json.dumps(payload)
            )
            return response['Payload'].read().decode('utf-8')
        except Exception as e:
            honeybadger.notify(e, context={"function": self.function})
            return None


class TextDetection(Lambda):
    def __init__(self):
        super().__init__('autofund-page-classifier')

    @staticmethod
    def process(text):
        return json.loads(TextDetection()._process(
            {'text': text, 'multi_page': 'false'}
        ))


class TextractAnalysis(Lambda):
    def __init__(self):
        super().__init__('textract-analysis')

    @staticmethod
    def process(uri):
        parts = urlparse(uri).path[1:].rsplit('/', 1)
        return json.loads(TextractAnalysis()._process(
            {'input_file': {'prefix': parts[0], 'file_name': parts[-1]}, 'features': ['OCR']}
        ))
