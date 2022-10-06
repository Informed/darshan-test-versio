module "api_handler_dynamodb_table" {
  # tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/informed/borg.git//aws-dynamodb-table"

  name                           = "${var.project_name}-${var.environment}-api-handler"
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
