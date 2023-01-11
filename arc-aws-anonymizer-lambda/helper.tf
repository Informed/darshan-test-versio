locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "src_bucket" {
  bucket   = var.src_bucket
  provider = aws.source
}

data "aws_s3_bucket" "dest_bucket" {
  bucket   = var.dest_bucket
  provider = aws.dest
}

data "archive_file" "anonymizer-package" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = ".terraform/modules/anonymized_lambda/arc-aws-anonymizer-lambda/out/anonymizer.zip"
}
