import app.schemas.v1.create_application_request
from os import path


def start():
    basepath = path.dirname(__file__) + '/../../api-specs'

    filepath = path.abspath(path.join(basepath, 'create_application.json'))
    with open(filepath, 'w') as outfile:
        outfile.write(app.schemas.v1.create_application_request.CreateApplicationRequest
                         .schema_json(indent=4))

    print('Api Spec generation completed!')
