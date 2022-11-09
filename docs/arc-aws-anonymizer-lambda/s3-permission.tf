#### Bucket permission ###
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = data.aws_s3_bucket.destination_bucket.id
  provider = aws.dest
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:s3:::${data.aws_s3_bucket.destination_bucket.id}/*"]
    actions   = ["s3:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:role/${module.copy_lambda_function.lambda_role_name}","arn:aws:iam::${local.account_id}:role/${module.delete_lambda_function.lambda_role_name}"]
    }
  }
}