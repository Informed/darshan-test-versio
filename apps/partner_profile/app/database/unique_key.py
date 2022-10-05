import app.helpers.setup_logging


class UniqueKey:
    UNIQUE_FIELDS = {
        'analyzeIq': [],
        'collectIq': ['subdomain'],
        'metadata': ['name', 'email'],
        'monitoringAlerting': [],
        'redaction': [],
        'serialization': [],
        'stipulationCreationRules': [],
        'stipulationVerificationConfig': [],
        'verifyIq': ['subdomain'],
    }

    def __init__(self, sort_key):
        self.log = app.helpers.setup_logging.SetupLogging()
        self.sort_key = sort_key

    def create_unique_keys(self, new_item):
        items = []
        for field in UniqueKey.UNIQUE_FIELDS[self.sort_key]:
            if not new_item.get(field):
                continue

            items.append({
                'PK': self.generate_partition_key(field, new_item.get(field)),
                'SK': 'unique_key', 'uuid': new_item.get('PK')
            })

        return items

    def update_unique_keys(self, new_item, prev_item):
        put_items = []
        delete_items = []
        for field in UniqueKey.UNIQUE_FIELDS.get(self.sort_key):
            if new_item.get(field) == prev_item.get(field):
                continue

            if new_item.get(field):
                put_items.append({
                    'PK': self.generate_partition_key(field, new_item.get(field)),
                    'SK': 'unique_key', 'uuid': new_item.get('PK')
                })
            if prev_item.get(field):
                delete_items.append({
                    'PK': self.generate_partition_key(field, prev_item.get(field)),
                    'SK': 'unique_key'
                })

        return [put_items, delete_items]

    def delete_unique_keys(self, item):
        delete_items = []
        for field in UniqueKey.UNIQUE_FIELDS[self.sort_key]:
            if item.get(field):
                delete_items.append({
                    'PK': self.generate_partition_key(field, item.get(field)),
                    'SK': 'unique_key'
                })

        return delete_items

    def generate_partition_key(self, field, value):
        return f"{self.sort_key}#{field}#{value}"
