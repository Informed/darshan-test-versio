import logging
import os


class SetupLogging:
    def __init__(self):
        log_level = os.environ['LOG_LEVEL']
        self.logger = logging.getLogger(__name__)
        logging.getLogger().setLevel(log_level)

    # Logs data which can be viewed/queried in AWS CloudWatch
    def info(self, log):
        self.logger.info(log)
