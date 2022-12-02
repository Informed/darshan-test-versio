class AwsDynamoDb
  VERSION ||= 'version'.freeze

  class << self
    # helper to generate hash needed for primary key
    def primary_key(partition_key, partition_value, sort_key = nil, sort_value = nil)
      pk = { partition_key => partition_value }
      return pk.merge(sort_key => sort_value) if sort_key
      pk
    end
  end

  def initialize(table)
    resource = Aws::DynamoDB::Resource.new
    @table = resource.table("techno-core-#{ENV.fetch('Environment', 'dev')}-#{table}")
  end

  def insert(item_hash, versioned: false)
    attrs = { item: item_hash }
    if versioned
      prev_version = item_hash[VERSION]
      item_hash[VERSION] = prev_version ? prev_version + 1 : 1
      condition = "#{VERSION} = :prev_version" if prev_version
      condition ||= "attribute_not_exists(#{VERSION})"
      attrs[:condition_expression] = condition
      attrs[:expression_attribute_values] = { ':prev_version' => prev_version } if prev_version
    end
    @table.put_item(**attrs)
  rescue Aws::DynamoDB::Errors::ValidationException => e
    Honeybadger.notify(e, context: { table_name: @table.name, item: attrs })
  end

  def fetch(key, value_key = nil, raw_item: false)
    raise ArgumentError, 'Cannot pass both value_key and raw_item' if value_key.present? & raw_item
    item = @table.get_item(key: key)
    return item if raw_item
    item = item.item
    return item[value_key] if item && value_key
    item
  rescue Aws::DynamoDB::Errors::ResourceNotFoundException
    nil
  end
end
