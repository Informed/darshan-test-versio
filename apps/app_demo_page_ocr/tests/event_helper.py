import copy

from aws_lambda_powertools.utilities.typing import LambdaContext

BASE_EVENT = {
    "version": "0",
    "id": "<AWS UUID>",
    "detail-type": "ImageProcessStart",
    "source": ["imageConverter"],
    "account": "<AWS Account ID>",
    "time": "<AWS Event Creation ISO 8601 datetime>",
    "region": "<AWS Region>",
    "resources":
    [],
    "detail":
    {
        "metadata":
        {
            "traceparent": "00-00-00-00"
        },
        "data":
        {
            "application_id": "1cb8d796-1cf9-4642-9589-c422042d02a8",
            "partner_id": "AAAAaaaa-aaaa-AAaa-aaAA-aaaaAAAA",
            "jwt": "",
            "resource_id": "f2a02149-841a-4ba9-8718-c8f923461369",
            "resource_type": "file",
            "job_id": "e3e447f6-f8fc-4dcf-96ba-7fb7c66717e6",
            "page_number": 1,
            "total_pages": 10,
            "page_uri": "s3://informed-techno-core-dev-exchange/AAAAaaaa-aaaa-AAaa-aaAA-aaaaAAAA/1cb8d796-1cf9-4642-9589-c422042d02a8/f2a02149-841a-4ba9-8718-c8f923461369/00075c36-6004-441a-99e3-0b5efe5c4072.png#iTb3_PuvnVEA5wu1u4mL1FJtawqBqm7s"  # noqa: B950
        }
    }
}


class MockLambdaContext(LambdaContext):

    def __init__(self):
        self._function_name = 'app_demo_page_ocr'
        self._memory_limit_in_mb = 128
        self._invoked_function_arn = 'arn:aws:lambda:'
        self._aws_request_id = '1234'


def context() -> LambdaContext:
    return MockLambdaContext()


def event_copy():
    return copy.deepcopy(BASE_EVENT)


def event_data(data_args=None, metadata_args=None):
    if data_args is None:
        data_args = {}
    if metadata_args is None:
        metadata_args = {}
    copy = event_copy()
    copy['detail']['data'].update(**data_args)
    copy['detail']['metadata'].update(**metadata_args)
    return copy
