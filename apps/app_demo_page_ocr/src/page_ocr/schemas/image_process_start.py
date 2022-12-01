IMAGE_PROCESS_START = {
    "definitions": {
        "Metadata": {
            "type": "object",
            "required": [
                "traceparent"
            ],
            "properties": {
                "traceparent": {
                    "type": "string"
                }
            }
        },
        "Data": {
            "type": "object",
            "required": [
                "partner_id",
                "application_id",
                "resource_id",
                "resource_type",
                "page_number",
                "total_pages",
                "page_uri",
                "job_id"
            ],
            "properties": {
                "partner_id": {
                    "type": "string"
                },
                "application_id": {
                    "type": "string"
                },
                "resource_id": {
                    "type": "string"
                },
                "resource_type": {
                    "type": "string"
                },
                "page_number": {
                    "type": "integer"
                },
                "total_pages": {
                    "type": "integer"
                },
                "page_uri": {
                    "type": "string"
                },
                "job_id": {
                    "type": "string"
                }
            }
        }
    },
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "Root",
    "type": "object",
    "required": [
        "metadata", "data"
    ],
    "properties": {
        "metadata": {
            "$ref": "#definitions/Metadata"
        },
        "data": {
            "$ref": "#definitions/Data"
        }
    }
}
