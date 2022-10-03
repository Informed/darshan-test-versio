import app.database.parameter_store
import app.helpers.setup_logging

from honeybadger import honeybadger

import jwt
import os
import traceback


class Jwt:
    def __init__(self):
        self.log = app.helpers.setup_logging.SetupLogging()

    def env(self):
        return os.environ.get('Environment')

    def validate_jwt(self, encoded_jwt, raw_path):
        self.log.info("JWT Helper: start validate_jwt for {path}".format(path=raw_path))
        secret = self.jwt_secret()
        try:
            partner_info = jwt.decode(encoded_jwt, secret, algorithms=["HS256"])
            self.log.info("JWT Helper: end validate_jwt for {path}".format(path=raw_path))
            return [True, partner_info]
        except Exception as e:
            self.log.info("Invalid JWT for path: {path}".format(path=raw_path))
            honeybadger.notify(e, context={
                'raw_path': raw_path,
                'error_info': repr(e),
                'traceback': traceback.print_exc()
            })
            self.log.info("JWT Helper: end validate_jwt for {path}".format(path=raw_path))
            return [False, {}]

    def jwt_secret(self):
        secret_name = f"/tc/{self.env()}/admin/credentials/jwt"
        return app.database.parameter_store.ParameterStore() \
                           .get(secret_name)
