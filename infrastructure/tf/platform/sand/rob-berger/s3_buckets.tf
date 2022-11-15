##
## S3 Bucket wtih some "public" access via pre-signed URLs
##

locals {
  bucket_name = "${var.bucket_prefix}-${var.project_name}-${var.environment}-downloads"
  partition   = join("", data.aws_partition.current.*.partition)
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.scope_prefix}-download-bucket"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "bucket_policy" {
  # This emulates the terraform-aws-s3-bucket mechanism for supplying a map of principals and prefixes
  # https://registry.terraform.io/modules/cloudposse/s3-bucket/aws/latest#input_privileged_principal_arns
  dynamic "statement" {
    for_each = var.additional_download_bucket_privileged_principal_arns

    content {
      sid = "AllowPrivilegedPrincipal[${statement.key}]" # add indices to Sid
      actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectVersionTagging",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAttributes",
        "s3:GetObjectVersion",
        "s3:ListBucketVersions",
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:GetBucketLocation",
      ]

      resources = distinct(flatten([
        "arn:${local.partition}:s3:::${local.bucket_name}",
        formatlist("arn:${local.partition}:s3:::${local.bucket_name}/%s*", values(statement.value)[0]),
      ]))
      principals {
        type        = "AWS"
        identifiers = [keys(statement.value)[0]]
      }
    }
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.this.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
    ]
  }
}

module "download_bucket" {
  # tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/informed/borg.git//aws-s3-bucket"

  bucket_name = local.bucket_name

  # Bucket policies
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.bucket_policy.json
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # S3 Bucket Ownership Controls
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  expected_bucket_owner = data.aws_caller_identity.current.account_id

  acl = "private" # "acl" conflicts with "grant" and "owner"

  logging = {
    target_bucket = module.log_storage_bucket.bucket_id
    target_prefix = "${local.scope_prefix}-${var.environment}-download-bucket"
  }

  versioning = {
    status     = true
    mfa_delete = false
  }

  cors_rule = [
    {
      allowed_methods = ["GET"]
      allowed_origins = ["*"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
}

#####################
## Exchange Bucket ##
#####################

module "exchange_bucket" {
  source                    = "../../../modules/s3_bucket"
  environment               = var.environment
  bucket_prefix             = var.bucket_prefix
  project_name              = var.project_name
  bucket_base_name          = "exchange"
  log_storage_bucket_id     = module.log_storage_bucket.bucket_id
  log_storage_bucket_prefix = "${local.scope_prefix}-${var.environment}-exchange-bucket"
  privileged_principal_arns = concat(
  var.additional_exchange_bucket_privileged_principal_arns)
  privileged_principal_actions = [
    "s3:PutObject",
    "s3:GetObject",
    "s3:GetObjectVersionTagging",
    "s3:GetObjectVersionAcl",
    "s3:GetObjectVersionForReplication",
    "s3:GetObjectVersionAttributes",
    "s3:GetObjectVersion",
    "s3:ListBucketVersions",
    "s3:ListBucket",
    "s3:GetBucketVersioning",
    "s3:GetBucketLocation",
  ]
}

####################
## Uploads Bucket ##
####################

module "upload_bucket" {
  source                    = "../../../modules/s3_bucket"
  bucket_prefix             = var.bucket_prefix
  project_name              = var.project_name
  environment               = var.environment
  bucket_base_name          = "uploads"
  eventbridge_enable        = true
  log_storage_bucket_id     = module.log_storage_bucket.bucket_id
  log_storage_bucket_prefix = "${local.scope_prefix}-${var.environment}-upload-bucket"
  cors_rule_inputs = [
    {
      allowed_methods = ["POST", "PUT"]
      allowed_origins = ["*"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3600
    }
  ]
  privileged_principal_arns = var.additional_upload_bucket_privileged_principal_arns
  privileged_principal_actions = [
    "s3:PutObject",
    "s3:GetObject",
    "s3:GetObjectVersionTagging",
    "s3:GetObjectVersionAcl",
    "s3:GetObjectVersionForReplication",
    "s3:GetObjectVersionAttributes",
    "s3:GetObjectVersion",
    "s3:ListBucketVersions",
    "s3:ListBucket",
    "s3:GetBucketVersioning",
    "s3:GetBucketLocation",
  ]
}

# Create a bucket for storing access logs
# Assumes there will be a prefix for each service logging to here
locals {
  lifecycle_configuration_rule = {
    enabled = true # bool
    id      = "v2rule"

    abort_incomplete_multipart_upload_days = 1 # number

    filter_and = null
    expiration = {
      days = 120 # integer > 0
    }
    noncurrent_version_expiration = {
      newer_noncurrent_versions = 3  # integer > 0
      noncurrent_days           = 60 # integer >= 0
    }
    transition = [{
      days          = 60            # integer >= 0
      storage_class = "STANDARD_IA" # string/enum, one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR.
      },
      {
        days          = 90           # integer >= 0
        storage_class = "ONEZONE_IA" # string/enum, one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR.
    }]
    noncurrent_version_transition = [{
      newer_noncurrent_versions = 3            # integer >= 0
      noncurrent_days           = 30           # integer >= 0
      storage_class             = "ONEZONE_IA" # string/enum, one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR.
    }]
  }
}

module "log_storage_bucket" {
  source                        = "cloudposse/s3-log-storage/aws"
  version                       = "0.28.0"
  name                          = "logs"
  environment                   = var.environment
  namespace                     = var.project_name
  lifecycle_configuration_rules = [local.lifecycle_configuration_rule]
}

###############################
## Eventbridge Upload Bucket ##
###############################

data "aws_ssm_parameter" "auth_value" {
  name = "/tc/${var.environment}/terraform/rails_adapter/webhook"
}

module "eventbridge_upload_bucket" {
  source                        = "terraform-aws-modules/eventbridge/aws"
  version                       = "1.14.1"
  create_bus                    = false
  create_role                   = false
  create_connections            = var.eventbridge_create_api_destinations
  create_api_destinations       = var.eventbridge_create_api_destinations
  create_targets                = var.eventbridge_create_api_destinations
  attach_api_destination_policy = var.eventbridge_create_api_destinations

  rules = {
    "${local.scope_prefix}_input_file_received" = {
      description = "Rule for input_file_received event with webhook"
      event_pattern = jsonencode({
        "source" : ["aws.s3"],
        "detail-type" : ["Object Created"],
        "detail" : {
          "bucket" : {
            "name" : [module.upload_bucket.bucket_id]
          }
        }
      })
    }
  }

  targets = {
    "${local.scope_prefix}_input_file_received" = [
      {
        name            = "${local.scope_prefix}_input_file_received_webhook"
        destination     = "${local.scope_prefix}_input_file_received_webhook"
        attach_role_arn = module.custom_eventbus.eventbridge_role_arn
        dead_letter_arn = aws_sqs_queue.eventbridge_deadletter.arn
      },
      {
        name            = "${local.scope_prefix}-techno-core-eventbridge"
        arn             = module.custom_eventbus.eventbridge_bus_arn
        attach_role_arn = module.custom_eventbus.eventbridge_role_arn
        dead_letter_arn = aws_sqs_queue.eventbridge_deadletter.arn
      }
    ]
  }

  connections = {
    "${local.scope_prefix}_input_file_received_webhook" = {
      authorization_type = "API_KEY"
      auth_parameters = {
        api_key = {
          key   = "X_CUSTOM_AUTH"
          value = data.aws_ssm_parameter.auth_value.value
        }
      }
    }
  }

  api_destinations = {
    "${local.scope_prefix}_input_file_received_webhook" = {
      description                      = "The ${var.environment} input_file_received Adapter"
      invocation_endpoint              = "https://api-internal.dev.${var.dns_base_domain}/v1/event_hook/input_file_received"
      http_method                      = "POST"
      invocation_rate_limit_per_second = 20
    }
  }
}

###################
## Lambda Bucket ##
###################
resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = "${var.bucket_prefix}-${var.project_name}-${var.environment}-lambda-images"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}
