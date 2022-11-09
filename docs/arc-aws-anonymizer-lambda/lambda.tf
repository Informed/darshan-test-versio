module "copy_lambda_function" {
  source = "git::https://github.com/informed/borg.git//aws-lambda"
  function_name = "anonymized-copy-${var.app_name}"
  handler       = "copy_data.lambda_handler"
  runtime       = "python3.9"
  role_name        = "anonymized-copy"
  role_description = "used for copy lambda function"
  attach_policy_statements = true
  policy_statements = {
    s3 = {
      effect    = "Allow",
      actions   = ["s3:*"]
      resources = ["arn:aws:s3:::${data.aws_s3_bucket.destination_bucket.id}/*","arn:aws:s3:::${data.aws_s3_bucket.data_bucket1.id}/*"]
    }
  }

  source_path = "${path.module}/src/copy_data.py"

  environment_variables = {
    TARGET_BUCKET = var.destination_bucket
  }
  tags = {
    Name = "anonymized-copy"
  }
  providers = {
    aws = aws.source
  }

}

module "delete_lambda_function" {
  source = "git::https://github.com/informed/borg.git//aws-lambda"

  function_name = "anonymized-delete-${var.app_name}"
  handler       = "delete_data.lambda_handler"
  runtime       = "python3.9"

  role_name        = "anonymized-delete"
  role_description = "used for delete lambda function"
  attach_policy_statements = true
  policy_statements = {
    s3 = {
      effect    = "Allow",
      actions   = ["s3:*"]
      resources = ["arn:aws:s3:::${data.aws_s3_bucket.destination_bucket.id}/*","arn:aws:s3:::${data.aws_s3_bucket.data_bucket1.id}/*"]
    }
  }

  source_path = "${path.module}/src/delete_data.py"

  tags = {
    Name = "anonymized-delete"
  }
  providers = {
    aws = aws.source
  }
}