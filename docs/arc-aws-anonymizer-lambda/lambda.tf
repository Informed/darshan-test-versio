data "aws_iam_policy_document" "lambda_inline" {
  statement {
    sid    = "s3LambdaAllow"
    effect = "Allow"

    resources = [
      "arn:aws:s3:::${data.aws_s3_bucket.dest_bucket.id}/*",
      "arn:aws:s3:::${data.aws_s3_bucket.src_bucket.id}/*",
    ]
    actions = ["s3:*"]
  }
}

module "copy_lambda_function" {
  source                   = "git::https://github.com/informed/borg.git//aws-lambda"
  function_name            = "anonymized-copy-${var.app_name}"
  handler                  = "copy_data.lambda_handler"
  runtime                  = "python3.9"
  role_name                = "anonymized-copy"
  role_description         = "Used for copy anonymized data to destination bucket"
  attach_policy_statements = true
  policy_statements        = data.aws_iam_policy_document.lambda_inline.json

  source_path = "${path.module}/src/copy_data.py"

  environment_variables = {
    TARGET_BUCKET = var.dest_bucket
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

  role_name                = "anonymized-delete"
  role_description         = "Delete anonymized data from destination bucket as soon as its deleted from Source bucket"
  attach_policy_statements = true
  policy_statements        = data.aws_iam_policy_document.lambda_inline.json

  source_path = "${path.module}/src/delete_data.py"

  tags = {
    Name = "anonymized-delete"
  }
  providers = {
    aws = aws.source
  }
}