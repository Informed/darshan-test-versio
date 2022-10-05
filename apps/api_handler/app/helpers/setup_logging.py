from opentelemetry import trace

import os
import logging


class SetupLogging:
    def __init__(self):
        log_level = os.environ['LOG_LEVEL']
        self.logger = logging.getLogger(__name__)
        logging.getLogger().setLevel(log_level)
        self.span = trace.get_current_span()

    # Logs data which can be viewed/queried in AWS CloudWatch
    def add_log(self, log):
        self.logger.info(log)

    # Adds an event to the current span,
    # which can be viewed in honeycomb
    def add_event(self, event):
        self.span.add_event(event)

    def info(self, data):
        self.add_log(data)
        self.add_event(data)

    def set_attributes(self, attributes):
        self.span.set_attributes(attributes)
