locals {
    account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "data_bucket1" {
  bucket = var.source_bucket
  provider = aws.source
}
data "aws_s3_bucket" "destination_bucket" {
  bucket  = var.destination_bucket
  provider = aws.dest
}