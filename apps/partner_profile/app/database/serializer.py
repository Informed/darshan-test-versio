import app.helpers.setup_logging


class Serializer:
    MAPPING = {
        'collectIq': [
            ['subdomain', 'gsi1pk']
        ],
        'metadata': [
            ['email', 'gsi1pk'],
            ['name', 'gsi2pk']
        ],
        'verifyIq': [
            ['subdomain', 'gsi1pk']
        ]
    }

    def __init__(self):
        self.log = app.helpers.setup_logging.SetupLogging()

    def base_serialize(self, sort_key, item):
        # Set GSI keys
        for attribute, index_name in self.MAPPING.get(sort_key, []):
            item = self.set_gsi(item, attribute, index_name)

        return item

    def set_gsi(self, item, index_key, gsi_key):
        if index_key not in item.keys():
            return item

        if not item.get(index_key):
            item.pop(index_key, None)
            return item

        item[gsi_key] = item.get(index_key, None)
        item.pop(index_key, None)
        return item

    def base_deserialize(self, sort_key, item):
        # Unset GSI keys
        for attribute, index_name in self.MAPPING.get(sort_key, []):
            item = self.unset_gsi(item, attribute, index_name)

        return item

    def unset_gsi(self, item, index_key, gsi_key):
        if gsi_key not in item.keys():
            return item

        item[index_key] = item.get(gsi_key, None)
        item.pop(gsi_key, None)

        return item
