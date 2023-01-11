## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.2.7 |
| aws | ~> 4.6 |

## Providers

| Name | Version |
|------|---------|
| archive | n/a |
| aws | ~> 4.6 |
| aws.dest | ~> 4.6 |
| aws.source | ~> 4.6 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| copy\_lambda\_function | git::https://github.com/informed/borg.git//aws-lambda | n/a |
| delete\_lambda\_function | git::https://github.com/informed/borg.git//aws-lambda | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_lambda_permission.aws-lambda-trigger-copy-permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.aws-lambda-trigger-delete-permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket_notification.aws-lambda-trigger-copy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_policy.allow_access_from_another_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [archive_file.anonymizer-package](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.allow_access_from_another_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_s3_bucket.dest_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_s3_bucket.src_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app\_name | Application name | `string` | n/a | yes |
| dest\_bucket | dynamodb table | `string` | n/a | yes |
| environment | Name of this environment | `string` | n/a | yes |
| src\_bucket | backend key | `string` | n/a | yes |
| region | Region to deploy terraform resources to | `string` | `"us-west-2"` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

No outputs.
