module "app_demo_verification_service_cache_dynamodb_table" {
  # tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/informed/borg.git//aws-dynamodb-table"

  name                           = "${var.project_name}-${var.environment}-app-demo-verification-service"
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
    }
  ]
}
