# Platform

<!-- markdownlint-disable -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.6 |
| <a name="requirement_awsutils"></a> [awsutils](#requirement\_awsutils) | >= 0.11.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.24.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm_request_certificate"></a> [acm\_request\_certificate](#module\_acm\_request\_certificate) | cloudposse/acm-request-certificate/aws | 0.16.0 |
| <a name="module_custom_eventbus"></a> [custom\_eventbus](#module\_custom\_eventbus) | terraform-aws-modules/eventbridge/aws | 1.14.2 |
| <a name="module_download_bucket"></a> [download\_bucket](#module\_download\_bucket) | git::https://github.com/informed/borg.git//aws-s3-bucket | n/a |
| <a name="module_eventbridge_upload_bucket"></a> [eventbridge\_upload\_bucket](#module\_eventbridge\_upload\_bucket) | terraform-aws-modules/eventbridge/aws | 1.14.1 |
| <a name="module_exchange_bucket"></a> [exchange\_bucket](#module\_exchange\_bucket) | ../../modules/s3_bucket | n/a |
| <a name="module_legacy_dynamodb_tables"></a> [legacy\_dynamodb\_tables](#module\_legacy\_dynamodb\_tables) | ../../modules/dynamodb | n/a |
| <a name="module_log_storage_bucket"></a> [log\_storage\_bucket](#module\_log\_storage\_bucket) | cloudposse/s3-log-storage/aws | 0.28.0 |
| <a name="module_upload_bucket"></a> [upload\_bucket](#module\_upload\_bucket) | ../../modules/s3_bucket | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | git::https://github.com/informed/borg.git//aws-vpc | n/a |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | git::https://github.com/informed/borg.git//aws-vpc/modules/vpc-endpoints | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_account.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account) | resource |
| [aws_apigatewayv2_api.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_api_mapping.api_mapping_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping) | resource |
| [aws_apigatewayv2_authorizer.authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_authorizer) | resource |
| [aws_apigatewayv2_domain_name.domain_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name) | resource |
| [aws_apigatewayv2_stage.stage_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_cloudwatch_log_group.all-eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.api_gateway_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.lambda_authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.authorizer-otel-permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.invoke_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.lambda_authorizer_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.authorizer-otel-permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.codeguru](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.invoke_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_authorizer_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.lambda_authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_route53_record.route53_record_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.lambda_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.lambda_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_schemas_discoverer.custom_eventbus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/schemas_discoverer) | resource |
| [aws_security_group.vpc_tls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_sqs_queue.eventbridge_deadletter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_ssm_parameter.api_gateway_api_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.api_gateway_authorizer_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.eventbridge_full_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.authorizer_otel_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudwatch_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.dynamodb_endpoint_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.endpoint_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.invoke_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_authorizer_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.parameter_store_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.api_zone_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_ssm_parameter.auth_value](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_download_bucket_privileged_principal_arns"></a> [additional\_download\_bucket\_privileged\_principal\_arns](#input\_additional\_download\_bucket\_privileged\_principal\_arns) | Additional download bucket privileged principal arns<br><br>  List of maps with the following:<br>  - Key: arn of the role or user to grant access to the bucket<br>  - Value: a list of the actions to grant to the role or user<br><br>  These will be concatinated to the existing list of privileges in main.tf<br><br>  Example:<br>  [<br>    {"arn:aws:iam::123456789012:role/lambda-role" = ["*/*/app\_request/"]},<br>    {"arn:aws:iam::123456789012:user/lambda-user" = ["*/*/app\_request/"]}<br>  ] | `list(map(list(string)))` | `[]` | no |
| <a name="input_additional_exchange_bucket_privileged_principal_arns"></a> [additional\_exchange\_bucket\_privileged\_principal\_arns](#input\_additional\_exchange\_bucket\_privileged\_principal\_arns) | Additional exchange bucket privileged principal arns<br><br>  List of maps with the following:<br>  - Key: arn of the role or user to grant access to the bucket<br>  - Value: a list of the actions to grant to the role or user<br><br>  These will be concatinated to the existing list of privileges in main.tf<br><br>  Example:<br>  [<br>    {"arn:aws:iam::123456789012:role/lambda-role" = ["*/*/app\_request/"]},<br>    {"arn:aws:iam::123456789012:user/lambda-user" = ["*/*/app\_request/"]}<br>  ] | `list(map(list(string)))` | `[]` | no |
| <a name="input_additional_upload_bucket_privileged_principal_arns"></a> [additional\_upload\_bucket\_privileged\_principal\_arns](#input\_additional\_upload\_bucket\_privileged\_principal\_arns) | Additional upload bucket privileged principal arns<br><br>  List of maps with the following:<br>  - Key: arn of the role or user to grant access to the bucket<br>  - Value: a list of the actions to grant to the role or user<br><br>  These will be concatinated to the existing list of privileges in main.tf<br><br>  Example:<br>  [<br>    {"arn:aws:iam::123456789012:role/lambda-role" = ["*/*/app\_request/"]},<br>    {"arn:aws:iam::123456789012:user/lambda-user" = ["*/*/app\_request/"]}<br>  ] | `list(map(list(string)))` | `[]` | no |
| <a name="input_api_handler_honeybadger_api_key"></a> [api\_handler\_honeybadger\_api\_key](#input\_api\_handler\_honeybadger\_api\_key) | API Key for API Handler Honeybadger access | `string` | `"hbp_2xj5epE6rHbEgxxkw95dDSQ5O4iESx3F6GDE"` | no |
| <a name="input_authorizer_architectures"></a> [authorizer\_architectures](#input\_authorizer\_architectures) | lambda architecture to use | `list(string)` | <pre>[<br>  "x86_64"<br>]</pre> | no |
| <a name="input_authorizer_extra_environment_variables"></a> [authorizer\_extra\_environment\_variables](#input\_authorizer\_extra\_environment\_variables) | Additional / override Authorizer lambda environment variables | `map(string)` | `{}` | no |
| <a name="input_authorizer_handler"></a> [authorizer\_handler](#input\_authorizer\_handler) | lambda handler to use | `string` | `"partner_authorizer.handler"` | no |
| <a name="input_authorizer_honeybadger_api_key"></a> [authorizer\_honeybadger\_api\_key](#input\_authorizer\_honeybadger\_api\_key) | API Key for Honeybadger access for Authorizer | `string` | `"hbp_qu0Y7vf1gSFxZj5tEdAUX87QGnyCSa0TmrMp"` | no |
| <a name="input_authorizer_layer_arns"></a> [authorizer\_layer\_arns](#input\_authorizer\_layer\_arns) | ARN of the layers to add | `list(string)` | <pre>[<br>  "arn:aws:lambda:us-west-2:901920570463:layer:aws-otel-python-amd64-ver-1-11-1:2"<br>]</pre> | no |
| <a name="input_authorizer_memory_size"></a> [authorizer\_memory\_size](#input\_authorizer\_memory\_size) | lambda memory size to use | `string` | `"3072"` | no |
| <a name="input_authorizer_runtime"></a> [authorizer\_runtime](#input\_authorizer\_runtime) | lambda runtime to use | `string` | `"python3.8"` | no |
| <a name="input_authorizer_timeout"></a> [authorizer\_timeout](#input\_authorizer\_timeout) | lambda timeout to use | `string` | `"30"` | no |
| <a name="input_authorizer_tracing_mode"></a> [authorizer\_tracing\_mode](#input\_authorizer\_tracing\_mode) | lambda tracing mode to use | `string` | `"Active"` | no |
| <a name="input_bucket_prefix"></a> [bucket\_prefix](#input\_bucket\_prefix) | Prefix for Buckets | `string` | `"informed"` | no |
| <a name="input_disable_layers"></a> [disable\_layers](#input\_disable\_layers) | Disable lambda layers if true | `bool` | `false` | no |
| <a name="input_dns_base_domain"></a> [dns\_base\_domain](#input\_dns\_base\_domain) | Base domain for the target domainnames | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Name of this environment | `string` | n/a | yes |
| <a name="input_eventbridge_create_api_destinations"></a> [eventbridge\_create\_api\_destinations](#input\_eventbridge\_create\_api\_destinations) | Should create the eventbridge api-destinations. Only false for when the target destination hasnt been built yet due to legacy code work | `bool` | `true` | no |
| <a name="input_honeybadger_force_report_data"></a> [honeybadger\_force\_report\_data](#input\_honeybadger\_force\_report\_data) | The force reporting for development and test environments.<br>    See [Honeybadger for Python: force\_report\_data](https://docs.honeybadger.io/lib/python/) | `bool` | `true` | no |
| <a name="input_informed_analyze_docs_backend_base_url"></a> [informed\_analyze\_docs\_backend\_base\_url](#input\_informed\_analyze\_docs\_backend\_base\_url) | Preprocessor link for analyze docs | `string` | n/a | yes |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Log level for the lambda functions | `string` | `"INFO"` | no |
| <a name="input_partner_profile_honeybadger_api_key"></a> [partner\_profile\_honeybadger\_api\_key](#input\_partner\_profile\_honeybadger\_api\_key) | API Key for Partner Profile Honeybadger access | `string` | `"hbp_PRwWENiasCPczk1r70XXFQ3dJEQCN52K6FWc"` | no |
| <a name="input_profile"></a> [profile](#input\_profile) | The profile to use for deploying resources | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of Project | `string` | `"techno"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region to deploy terraform resources into | `string` | `"us-west-2"` | no |
| <a name="input_response_handler_honeybadger_api_key"></a> [response\_handler\_honeybadger\_api\_key](#input\_response\_handler\_honeybadger\_api\_key) | API Key for Response Handler Honeybadger access | `string` | `"hbp_YoGxhMGnep5z81s27sJkfF4QrYyK5b14iaqC"` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Whether to have one nat gateway for all non-public subnets or one per subnet | `bool` | `true` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The VPC CIDR to use depending upon the environment | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_gateway_domain_name"></a> [api\_gateway\_domain\_name](#output\_api\_gateway\_domain\_name) | FQDN of the API Gateway |
| <a name="output_api_gateway_id"></a> [api\_gateway\_id](#output\_api\_gateway\_id) | n/a |
| <a name="output_authorizer_function_name"></a> [authorizer\_function\_name](#output\_authorizer\_function\_name) | Name of the custom authorizer Lambda function. |
| <a name="output_aws_apigatewayv2_api_api_gateway"></a> [aws\_apigatewayv2\_api\_api\_gateway](#output\_aws\_apigatewayv2\_api\_api\_gateway) | The api-gateway info |
| <a name="output_aws_apigatewayv2_api_mapping_api_mapping_resource"></a> [aws\_apigatewayv2\_api\_mapping\_api\_mapping\_resource](#output\_aws\_apigatewayv2\_api\_mapping\_api\_mapping\_resource) | The api-gateway dns mapping |
| <a name="output_lambda_authorizer_cloudwatch_log_group"></a> [lambda\_authorizer\_cloudwatch\_log\_group](#output\_lambda\_authorizer\_cloudwatch\_log\_group) | Cloudwatch log group for for the test lambda authorizer |
| <a name="output_lambda_bucket_name"></a> [lambda\_bucket\_name](#output\_lambda\_bucket\_name) | Name of the S3 bucket used to store the lambda authorizer function code. |
| <a name="output_stage_id"></a> [stage\_id](#output\_stage\_id) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable -->
