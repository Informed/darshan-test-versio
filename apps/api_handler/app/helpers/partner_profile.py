import app.helpers.setup_logging
import app.helpers.opentelemetry

from honeybadger import honeybadger

import boto3
import json
import os


class PartnerProfile:
    def __init__(self, partner_id):
        self.log = app.helpers.setup_logging.SetupLogging()
        self.partner_id = partner_id

    def env(self):
        return os.environ['Environment']

    def profile(self):
        self.log.info('Partner Profile Setup')
        try:
            client = boto3.client('lambda')
            function_name = 'techno-core-' + self.env() + '-partner-profile'
            payload = {
                "rawPath": f"/v1/partner_profiles/{self.partner_id}",
                "headers": {
                    "traceparent": app.helpers.opentelemetry.Opentelemetry().traceparent()
                },
                "requestContext": {
                    "http": {"method": "GET"},
                    "stage": "$default"
                }
            }

            response = client.invoke(
                FunctionName=function_name,
                InvocationType='RequestResponse',
                Payload=json.dumps(payload)
            ).get('Payload', None)

            body = json.loads(response.read()).get('body', '')
            self.log.info('Finished Partner Profile Setup')
            return json.loads(body)
        except Exception as e:
            self.log.info('Failed Partner Profile Setup')
            honeybadger.notify(e, context={
                'function_name': function_name,
                'payload': payload
            })
            return {}
