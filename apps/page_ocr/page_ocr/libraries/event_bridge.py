import json
import os
from time import gmtime, strftime

import boto3
from helpers.setup_logging import SetupLogging


class EventBridge:
    def __init__(self):
        self.log = SetupLogging()
        self.client = boto3.client('events')

    def env(self):
        return os.environ.get('Environment')

    def push_event(self, event_type, details):
        self.log.info(f"Event Bridge Helper: start push_event for {event_type}")
        self.client.put_events(Entries=[
            {
                'Time': strftime("%a, %d %b %Y %H:%M:%S +0000", gmtime()),
                'Source': 'pageOcr',
                'EventBusName': "techno-core-{env}".format(env=self.env()),
                'DetailType': event_type,
                'Detail': json.dumps(details)
            }
        ],)
        self.log.info(
            "Event Bridge Helper: end push_event for {type}".format(type=event_type))


EventBridge = EventBridge()
