# terraform-aws-s3-cross-region-replication
Terraform Module for managing s3 bucket cross-region replication.
----------------------

## What this module does
Set-up 2 buckets with replication with:
- Versioning enabled (required for replication) 
- Encryption with KMS keys (Make sure the primary bucket has KMS enabled)
- Both buckets will be private by default


## Required

- AWS provider >= 4.8
- Terraform 1.1.7 module provider inheritance block:
- You need to have versioning enabled for Source Bucket.

- `aws.source` - AWS provider alias for source account
- `aws.dest`   - AWS provider alias for destination account

### Variables

You can see description of each variable on `variables.tf` file. The ones that does not have a default value, are required.

```hcl

module "s3-cross-account-replication" {
  source             = "git::https://github.com/informed/borg.git//aws-s3-cross-account-replication"

  bucket_source_name = var.bucket_source_name
  source_region      = var.source_region
  dest_region        = var.dest_region
  # Optional variable
  #   bucket_dest_name             = var.bucket_dest_name
  #   replication_name             = var.replication_name
  #   versioning_enable            = var.versioning_enable
  #   destination_storage_class    = var.destination_storage_class

  providers = {
    aws.source = aws.source
    aws.dest   = aws.dest
  }
}
provider "aws" {
  alias  = "source"
  region = "us-west-2"
  profile = "your-profile"
}


provider "aws" {
  alias  = "dest"
  region = "us-east-2"
  profile = "your-profile"
}



```