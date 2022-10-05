import app.database.dynamo_db
import app.helpers.setup_logging

import simplejson as json


class Admin:
    def __init__(self):
        self.log = app.helpers.setup_logging.SetupLogging()
        self.dynamodb = app.database.dynamo_db.DynamoDb()

    def profile_admin_creds(self, event):
        self.log.info('Admin Controller - start profile_admin_creds')

        stored_password_path = self.dynamodb.fetch_item(
            'partner-profile-circleci', 'informed_admin'
        ).get('password')

        self.log.info('Admin Controller - end profile_admin_creds')
        return {'statusCode': 200, 'body': json.dumps({'password_path': stored_password_path})}
