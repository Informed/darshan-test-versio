module "copy_lambda_function" {
  source = "git::https://github.com/informed/borg.git//aws-lambda"

  function_name = "anonymized-copy-${var.app_name}"
  handler       = "copy_data.lambda_handler"
  runtime       = "python3.9"

  role_name                = "anonymized-copy-${var.app_name}"
  role_description         = "Used for copy anonymized data to destination bucket"
  attach_policy_statements = true
  policy_statements = {
    s3 = {
      effect    = "Allow",
      actions   = ["s3:*"]
      resources = ["arn:aws:s3:::${data.aws_s3_bucket.dest_bucket.id}/*", "arn:aws:s3:::${data.aws_s3_bucket.src_bucket.id}/*"]
    }
  }

  create_package         = false
  local_existing_package = "./out/anonymizer.zip"

  ignore_source_code_hash = true

  environment_variables = {
    "TARGET_BUCKET"                  = var.dest_bucket
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

  role_name                = "anonymized-delete-${var.app_name}"
  role_description         = "Delete anonymized data from destination bucket as soon as its deleted from Source bucket"
  attach_policy_statements = true
  policy_statements = {
    s3 = {
      effect    = "Allow",
      actions   = ["s3:*"]
      resources = ["arn:aws:s3:::${data.aws_s3_bucket.dest_bucket.id}/*", "arn:aws:s3:::${data.aws_s3_bucket.src_bucket.id}/*"]
    }
  }

  create_package         = false
  local_existing_package = "./out/anonymizer.zip"

  ignore_source_code_hash = true

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
