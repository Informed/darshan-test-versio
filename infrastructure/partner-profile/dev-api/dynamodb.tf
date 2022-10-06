module "partner_profile_dynamodb_table" {
  # tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/informed/borg.git//aws-dynamodb-table"

  name                           = "${var.project_name}-${var.environment}-partner-profile"
  point_in_time_recovery_enabled = true
  hash_key                       = "PK"
  range_key                      = "SK"
  attributes = [
    {
      name = "PK"
      type = "S"
    },
    {
      name = "SK"
      type = "S"
    },
    {
      name = "gsi1pk"
      type = "S"
    },
    {
      name = "gsi2pk"
      type = "S"
    }
  ]
  global_secondary_indexes = [
    {
      name            = "gsi2pk_index"
      hash_key        = "gsi2pk"
      range_key       = "SK"
      projection_type = "ALL"
    },
    {
      name            = "gsi1pk_index"
      hash_key        = "gsi1pk"
      range_key       = "SK"
      projection_type = "ALL"
    }
  ]
}

# Can't actually use moved since its a external module
# Use the command
# terraform state mv 'module.partner_profile.aws_dynamodb_table.lambda' 'module.partner_profile_dynamodb_table.aws_dynamodb_table.this[0]'
# moved {
#   from = module.partner_profile.aws_dynamodb_table.lambda
#   to   = module.partner_profile_dynamodb_table.aws_dynamodb_table.this[0]
# }
