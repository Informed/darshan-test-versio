# Input event structure
# {
#     "partner_id": "partner_id",
#     "application_id": "application_id",
#     "file_id": "file_id",
#     "page_number": "page_number",
#     "total_pages": "total_pages",
#     "page_uri": "s3_path#version"
# }

# Output event structure
# {
#     "partner_id": "partner_id",
#     "application_id": "application_id",
#     "file_id": "file_id",
#     "page_number": "page_number",
#     "total_pages": "total_pages",
#     "page_uri": "s3_path#version",
#     "data_uris": [
#         {
#             "source": "google",
#             "ocr_data_uri": "s3_path#version"
#         }
#     ]
# }

import cv2
import os
import app.helpers.event_bridge
import app.helpers.setup_logging
from honeybadger import honeybadger

# Anytime an exception is raised, it triggers a
# HoneyBadger in page_ocr project
honeybadger.configure(
    api_key=os.environ.get('HONEYBADGER_API_KEY'),
    environment=os.environ.get('HONEYBADGER_ENVIRONMENT'),
    force_report_data=os.environ.get('HONEYBADGER_FORCE_REPORT_DATA', 'true')
)


def handler(event, context):
    log = app.helpers.setup_logging.SetupLogging()
    event_data = event.get('detail', {})
    log.info(event_data)
    if all(key in event_data for key in ("partner_id", "application_id", "file_id", "page_number", "total_pages", "page_uri")):  # noqa: B950
        log.info("Input event structure is valid!")
        details = {
            "partner_id": event_data.get("partner_id"),
            "application_id": event_data.get("application_id"),
            "file_id": event_data.get("file_id"),
            "page_number": event_data.get("page_number"),
            "total_pages": event_data.get("total_pages"),
            "page_uri": event_data.get("page_uri"),
            "data_uris": [
                {
                    "source": "google",
                    "ocr_data_uri": "s3_path#version"
                }
            ]
        }

        app.helpers.event_bridge.EventBridge().push_event("ImageProcessCompleted", details)
    else:
        log.info("Input event structure is invalid!")
        raise Exception(f"Invalid input event structure! - {event_data}")
