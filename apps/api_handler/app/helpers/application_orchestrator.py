import app.database.parameter_store
import app.helpers.setup_logging

import os
import requests


class ApplicationOrchestrator:
    def __init__(self):
        self.log = app.helpers.setup_logging.SetupLogging()

    def env(self):
        return os.environ['Environment']

    def endpoint(self):
        return os.environ.get('APPLICATION_ORCHESTRATOR_ENDPOINT')

    def rails_custom_header(self):
        secret_name = f"/tc/{self.env()}/terraform/rails_adapter/webhook"
        return app.database.parameter_store.ParameterStore().get(secret_name)

    def applications(self, version, params):
        url = f"{self.endpoint()}/{version}/applications/applications"

        return self.fetch_data(url, params)

    def application(self, version, application_id, all_questions):
        params = {"all_questions": all_questions}
        url = f"{self.endpoint()}/{version}/applications/{application_id}/details"

        return self.fetch_data(url, params)

    def documents(self, version, application_id, pages):
        params = {"pages": pages}
        url = f"{self.endpoint()}/{version}/applications/{application_id}/documents"  # noqa: B950

        return self.fetch_data(url, params)

    def query_params(self, params):
        result = []
        for key, value in params.items():
            result.append(f"{key}={value}")
        return "&".join(result)

    def fetch_data(self, url, params):
        headers = {"X_CUSTOM_AUTH": self.rails_custom_header()}
        r = requests.get(url, headers=headers, params=params)
        if r.status_code != 200:
            return {
                'status_code': 500,
                'body': {'message': 'Something went wrong :('}
            }

        return {"payload": r.json()}
