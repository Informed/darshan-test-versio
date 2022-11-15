module "copy_lambda_function" {
  source = "git::https://github.com/informed/borg.git//aws-lambda"

  function_name = "anonymized-copy-${var.app_name}"
  handler       = "copy_data.lambda_handler"
  runtime       = "python3.9"

  role_name                = "anonymized-copy"
  role_description         = "Used for copy anonymized data to destination bucket"
  attach_policy_statements = true
  policy_statements = {
    s3 = {
      effect    = "Allow",
      actions   = ["s3:*"]
      resources = ["arn:aws:s3:::${data.aws_s3_bucket.dest_bucket.id}/*", "arn:aws:s3:::${data.aws_s3_bucket.src_bucket.id}/*"]
    }
  }

  source_path = "${path.module}/src/copy_data.py"

  environment_variables = {
    "TARGET_BUCKET"                  = var.dest_bucket
    "ADD_DOCUMENTS_PII"              = var.add_documents_PII,
    "REMOVE_DOCUMENTS_PII"           = var.remove_documents_PII
    "ADD_APPLICATION_PII"            = var.add_application_PII
    "REMOVE_APPLICATION_PII"         = var.remove_application_PII
    "ADD_STIP_VERIFICATION_PII"      = var.add_stip_verification_PII
    "ADD_STIP_VERIFICATION_LIST_PII" = var.add_stip_verification_list_PII
    "REMOVE_STIP_VERIFICATION_PII"   = var.remove_stip_verification_PII
    "ADD_SKIP_THE_STIP_PII"          = var.add_skip_the_stip_PII
    "REMOVE_SKIP_THE_STIP_PII"       = var.remove_skip_the_stip_PII
  }

  tags = merge(
    var.tags,
    {
      "terraform-module"      = "true",
      "module-repository"     = "borg",
      "terraform-module-name" = "arc-aws-anonymizer-lambda",
      "type"                  = "anonymized-copy"
    }
  )
  providers = {
    aws = aws.source
  }
}

module "delete_lambda_function" {
  source = "git::https://github.com/informed/borg.git//aws-lambda"

  function_name = "anonymized-delete-${var.app_name}"
  handler       = "delete_data.lambda_handler"
  runtime       = "python3.9"

  role_name                = "anonymized-delete"
  role_description         = "Delete anonymized data from destination bucket as soon as its deleted from Source bucket"
  attach_policy_statements = true
  policy_statements = {
    s3 = {
      effect    = "Allow",
      actions   = ["s3:*"]
      resources = ["arn:aws:s3:::${data.aws_s3_bucket.dest_bucket.id}/*", "arn:aws:s3:::${data.aws_s3_bucket.src_bucket.id}/*"]
    }
  }

  source_path = "${path.module}/src/delete_data.py"

  environment_variables = {
    TARGET_BUCKET = var.dest_bucket
  }

  tags = merge(
    var.tags,
    {
      "terraform-module"      = "true",
      "module-repository"     = "borg",
      "terraform-module-name" = "arc-aws-anonymizer-lambda",
      "type"                  = "anonymized-delete"
    }
  )

  providers = {
    aws = aws.source
  }
}