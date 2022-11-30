import time
from contextlib import contextmanager

from aws_lambda_powertools import Metrics, single_metric
from aws_lambda_powertools.metrics import MetricUnit

from .default_dimensions import DefaultDimensions

metrics = Metrics()
METRIC_TYPE = 'metric_type'
COUNT = 'count'
GAUGE = 'gauge'
HISTOGRAM = 'histogram'
REQUEST_RECEIVED = 'RequestReceived'
SEVERITY = 'severity'

# LOG LEVELS
CRITICAL = 'critical'
ERROR = 'error'
WARNING = 'warning'
INFO = 'info'
DEBUG = 'debug'

SEVERITY_LEVELS = set((CRITICAL, ERROR, WARNING, INFO, DEBUG))


def count_metric(name, value=1, dimensions=None):
    with single_metric(name=name, unit=MetricUnit.Count, value=value) as metric:
        if dimensions:
            for (key, d_val) in dimensions.items():
                metric.add_dimension(name=key, value=d_val)


def time_metric(name, value, dimensions=None, unit=MetricUnit.Milliseconds):
    with single_metric(name=name, unit=unit, value=value) as metric:
        if dimensions:
            for (key, d_val) in dimensions.items():
                metric.add_dimension(name=key, value=d_val)


def size_metric(name, value, dimensions=None, unit=MetricUnit.Kilobytes):
    with single_metric(name=name, unit=unit, value=value) as metric:
        if dimensions:
            for (key, d_val) in dimensions.items():
                metric.add_dimension(name=key, value=d_val)


class MetricWrapper:
    TIMERS = {}

    def __init__(self, default_dimensions=None):
        self.default_dimensions = DefaultDimensions.get()
        # self.default_dimensions = {'env': os.environ.get(
        #     'Environment', 'dev'), **(default_dimensions or {})}

    # Generic methods

    def count(self, name, value=1, dimensions=None):
        if not dimensions or METRIC_TYPE not in dimensions:
            dimensions = dimensions or {}
            dimensions[METRIC_TYPE] = COUNT

        count_metric(name, value=value,
                     dimensions={**self.default_dimensions, **dimensions})

    def gauge(self, name, dimensions=None):
        self.count(name, dimensions={METRIC_TYPE: GAUGE, **(dimensions or {})})

    def histogram(self, name, dimensions=None):
        self.count(name, dimensions={METRIC_TYPE: HISTOGRAM, **(dimensions or {})})

    def time(self, name, value, dimensions=None, unit=MetricUnit.Milliseconds, metric_type=GAUGE):  # noqa: B950
        if not dimensions or METRIC_TYPE not in dimensions:
            dimensions = dimensions or {}
            dimensions[METRIC_TYPE] = metric_type
        time_metric(name, value=value,
                    dimensions={**self.default_dimensions, **dimensions},
                    unit=unit)

    # used to measure time for a single block of code, e.g.
    # with timer('BLOCK_OF_CODE_TIMER'):
    #     code_executes()
    #     other_code_executes()
    #
    # measures the amount of time taken for code_executes() and other_code_executes()
    @contextmanager
    def timer(self, name, dimensions=None, metric_type=GAUGE):
        start = int(time.time() * 1000)
        yield
        total = int(time.time() * 1000) - start
        self.time(name, total, dimensions=dimensions, unit=MetricUnit.Milliseconds, metric_type=metric_type)  # noqa: B950

    # timer_start and timer_stop are meant to measure time in instances where measuring
    # across a block of code is not feasible. `name` needs to be consistent across
    # _start and _stop calls for it to work, AND it needs to be using the same
    # MetricWrapper() instance, e.g.
    # wrapper = MetricWrapper()
    # wrapper.timer_start('DISTRIBUTED_CODE_TIMER')
    # wrapper.timer_stop('DISTRIBUTED_CODE_TIMER')
    def timer_start(self, name):
        self.TIMERS[name] = int(time.time() * 1000)

    def timer_stop(self, name, dimensions=None, metric_type=None):
        if name not in self.TIMERS:
            raise RuntimeError(f"Timer not started for: {name}")

        metric_type = metric_type or GAUGE
        total = int(time.time() * 1000) - self.TIMERS[name]
        del self.TIMERS[name]
        self.time(name, total, dimensions=dimensions, metric_type=metric_type)

    # Methods to track the same types of metrics we measure across all services

    def track_request_received(self):
        self.count(REQUEST_RECEIVED)

    def error(self, severity=ERROR, dimensions=None):
        if severity not in SEVERITY_LEVELS:
            raise RuntimeError(f"Invalid severity level: {severity}")
        dimensions = dimensions or {}
        dimensions[SEVERITY] = severity
        self.count('Error', dimensions=dimensions)
