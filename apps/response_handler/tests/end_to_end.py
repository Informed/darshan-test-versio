import argparse
import glob
import json
import os

from response_handler import handler
from datetime import datetime

# Instructions:
#
# Note: Delete/Clear the directory /apps/response_handler/tests/output_events
#
# 1. There are a set of sample tests already defined
#    in the folder /apps/response_handler/tests/input_events.
#    If you have any new tests to be added, you need to define
#    the event json in this folder. Make sure all the
#    s3 uris have files in s3 and versions are correct
#
# 2. You need to set .env file on your local with the following data
#       Environment=dev
#       AWS_REGION=us-west-2
#       AWS_PROFILE=dev
#       LOG_LEVEL=INFO
#       EVENT_TYPE=local
#
# 3. To run all the tests, use this commnd
#      poetry run dotenv run analyze-response-handler
#
# 4. To run only selected tests, use this command with comma separated file names
#      poetry run dotenv run analyze-response-handler --tests="sample_extraction_response.json,sample_verification_response.json"  # noqa: B950
#
# Note: Do not check the files inside /apps/response_handler/tests/output_events into git
#


def analyze():
    parser = argparse.ArgumentParser()
    parser.add_argument('--tests', dest='tests', default="")
    args = parser.parse_args()
    filenames = args.tests.split(",") if args.tests != '' else []

    basepath = os.path.dirname(__file__)
    input_events_path = basepath + '/input_events'
    output_events_path = basepath + '/output_events'

    if not os.path.exists(output_events_path):
        os.makedirs(output_events_path)

    if len(filenames) > 0:
        for filename in filenames:
            full_file_name = f"{input_events_path}/{filename}"
            process_file(full_file_name, output_events_path)
    else:
        for filename in glob.glob(os.path.join(input_events_path, '*.json')):
            process_file(filename, output_events_path)


def process_file(filename, output_events_path):
    with open(os.path.join(os.getcwd(), filename), 'r') as f:
        input_event = json.load(f)
        response = handler(input_event, {})
        event_detail = json.loads(response.get('body', {})).get('event_detail')

        filename = filename.split('/')[-1].replace('.json', '')
        output_filename = f"{output_events_path}/{filename.split('/')[-1]}-{datetime.now()}.json"  # noqa: B950

        with open(output_filename, "w") as outfile:
            outfile.write(json.dumps(event_detail, indent=2))
