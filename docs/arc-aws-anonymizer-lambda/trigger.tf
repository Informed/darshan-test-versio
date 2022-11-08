# Adding S3 bucket as trigger to my lambda and giving the permissions
resource "aws_s3_bucket_notification" "aws-lambda-trigger-copy" {
  provider = aws.source
  bucket = data.aws_s3_bucket.data_bucket1.id
  lambda_function {
    lambda_function_arn = module.copy_lambda_function.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]

  }
    lambda_function {
    lambda_function_arn = module.delete_lambda_function.lambda_function_arn
    events              = ["s3:ObjectRemoved:*"]

  }
}

resource "aws_lambda_permission" "aws-lambda-trigger-copy-permissions" {
  provider = aws.source
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.copy_lambda_function.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${data.aws_s3_bucket.data_bucket1.id}"
}

resource "aws_lambda_permission" "aws-lambda-trigger-delete-permissions" {
  provider = aws.source
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.delete_lambda_function.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${data.aws_s3_bucket.data_bucket1.id}"
}
