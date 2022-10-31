import app.database.parameter_store
from app.helpers.setup_logging import log

from honeybadger import honeybadger

import jwt
import os
import traceback


class Jwt:
    # TODO: these all can be changed into class method
    def env(self):
        return os.environ.get('Environment')

    def validate_jwt(self, encoded_jwt, event_type):
        log.info("JWT Helper: start validate_jwt for {path}".format(path=event_type))
        secret = self.jwt_secret()
        try:
            partner_info = jwt.decode(encoded_jwt, secret, algorithms=["HS256"])
            log.info("JWT Helper: end validate_jwt for {path}".format(path=event_type))
            return [True, partner_info]
        except Exception as e:
            log.info("Invalid JWT for path: {path}".format(path=event_type))
            honeybadger.notify(e, context={
                'event_type': event_type,
                'error_info': repr(e),
                'traceback': traceback.print_exc()
            })
            log.info("JWT Helper: end validate_jwt for {path}".format(path=event_type))
            return [False, {}]

    def jwt_secret(self):
        secret_name = f"/tc/{self.env()}/admin/credentials/jwt"
        return app.database.parameter_store.ParameterStore() \
                           .get(secret_name)
