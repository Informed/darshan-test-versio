resource "aws_dynamodb_table" "this" {
  name         = var.dynamodb_name
  billing_mode = var.billing_mode

  # This is for the table_autoscaling to  prevent Terraform from removing your scaling actions.
  lifecycle {
    ignore_changes = [
      write_capacity, read_capacity
    ]
  }


  ### Specify key used by encryption at rest
  ### false -> use AWS Owned CMK
  ### true -> use AWS Managed CMK
  ### true + key arn -> use custom key
  server_side_encryption {
    enabled     = var.server_side_encryption.enabled
    kms_key_arn = var.server_side_encryption.kms_key_arn
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  # Partition Key
  hash_key = var.hash_key.name
  # Sort Key
  range_key = var.range_key.name

  attribute {
    name = var.hash_key.name
    type = var.hash_key.type
  }

  attribute {
    name = var.range_key.name
    type = var.range_key.type
  }

  # TODO: Add support for global secondary indexes
  # # Will only create secondary indexes if they are defined in var.secondary_indexes
  # for_each = length(var.secondary_indexes) == 0 ? {} : var.secondary_indexes

  # attribute {
  #   name = each.value.hash_key
  #   type = each.value.type
  # }

  # global_secondary_index {
  #   name            = each.key
  #   hash_key        = each.value.hash_key
  #   range_key       = each.value.range_key
  #   projection_type = each.value.projection_type
  # }
}
