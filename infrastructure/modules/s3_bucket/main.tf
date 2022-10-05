module "cp_s3_bucket" {
  source  = "cloudposse/s3-bucket/aws"
  version = "2.0.2"


  acl                          = "private"
  enabled                      = true
  user_enabled                 = false
  versioning_enabled           = true
  bucket_key_enabled           = true
  name                         = var.bucket_base_name
  stage                        = var.environment
  namespace                    = "${var.bucket_prefix}-${var.project_name}"
  cors_rule_inputs             = length(var.cors_rule_inputs) == 0 ? null : var.cors_rule_inputs
  privileged_principal_arns    = var.privileged_principal_arns
  privileged_principal_actions = var.privileged_principal_actions
  logging = {
    bucket_name = var.log_storage_bucket_id,
    prefix      = var.log_storage_bucket_prefix
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = module.cp_s3_bucket.bucket_id
  eventbridge = var.eventbridge_enable
}
