# API Gateway and Authorizer Terraform Module

See the top level [README](../../README.md) for how the inputs are supplied

## Terraform information

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm_request_certificate"></a> [acm\_request\_certificate](#module\_acm\_request\_certificate) | cloudposse/acm-request-certificate/aws | 0.16.0 |

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_account.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account) | resource |
| [aws_apigatewayv2_api.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_api_mapping.api_mapping_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping) | resource |
| [aws_apigatewayv2_authorizer.authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_authorizer) | resource |
| [aws_apigatewayv2_domain_name.domain_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name) | resource |
| [aws_apigatewayv2_integration.analyze_docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.api_pass_thru](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.applications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.calculate_income](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.health_check](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.partner_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.partner_profile_query](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.partner_profiles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.partner_profiles_query](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.analzye_docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.api_pass_thru](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.application_slash](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.calculate_income](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.health_check](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.partner_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.partner_profile_query](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.partner_profiles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.partner_profiles_query](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.stage_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_cloudwatch_log_group.api_gateway_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.lambda_authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.authorizer-otel-permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.invoke_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.lambda_authorizer_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.authorizer-otel-permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.codeguru](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.invoke_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_authorizer_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.lambda_authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.api_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.partner_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_route53_record.route53_record_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.lambda_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.lambda_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_iam_policy_document.authorizer_otel_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudwatch_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.invoke_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_authorizer_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.parameter_store_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.api_zone_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alternative_names"></a> [alternative\_names](#input\_alternative\_names) | Alternative DNS names for the Certificate | `list(string)` | `[]` | no |
| <a name="input_analyze_docs_integration_description"></a> [analyze\_docs\_integration\_description](#input\_analyze\_docs\_integration\_description) | Description of the gateway integration for the analyze\_docs route | `string` | `""` | no |
| <a name="input_analyze_docs_versions"></a> [analyze\_docs\_versions](#input\_analyze\_docs\_versions) | The versions used for analyze docs routes | `list(any)` | `[]` | no |
| <a name="input_api_gateway_description"></a> [api\_gateway\_description](#input\_api\_gateway\_description) | Description of the API Gateway | `string` | `""` | no |
| <a name="input_api_gateway_domain_name"></a> [api\_gateway\_domain\_name](#input\_api\_gateway\_domain\_name) | Domain Name to assign to the API Gateway and its TLS Certificate | `string` | `""` | no |
| <a name="input_api_gateway_name"></a> [api\_gateway\_name](#input\_api\_gateway\_name) | Name of the API Gateway | `string` | `""` | no |
| <a name="input_api_handler_integration_description"></a> [api\_handler\_integration\_description](#input\_api\_handler\_integration\_description) | Description of the gateway integration for the api\_handler route | `string` | `""` | no |
| <a name="input_api_pass_thru_integration_description"></a> [api\_pass\_thru\_integration\_description](#input\_api\_pass\_thru\_integration\_description) | Description of the gateway integration for api routes other than calculate\_income and analyze\_docs | `string` | `""` | no |
| <a name="input_applications_path"></a> [applications\_path](#input\_applications\_path) | The HTTP Route path associated with api-handler applications | `string` | `""` | no |
| <a name="input_authorization_lambda_name"></a> [authorization\_lambda\_name](#input\_authorization\_lambda\_name) | Name of the custom authorizer Lambda | `string` | `""` | no |
| <a name="input_authorizer_honeybadger_api_key"></a> [authorizer\_honeybadger\_api\_key](#input\_authorizer\_honeybadger\_api\_key) | The api key for sending data to honeybadger for the authorizer | `string` | `""` | no |
| <a name="input_authorizer_name"></a> [authorizer\_name](#input\_authorizer\_name) | Name to be associated with the aws\_apigatewayv2\_authorizer | `string` | `""` | no |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID | `string` | `""` | no |
| <a name="input_aws_api_handler_lambda_function_name"></a> [aws\_api\_handler\_lambda\_function\_name](#input\_aws\_api\_handler\_lambda\_function\_name) | The function name of the apiHandler service lambda | `string` | `""` | no |
| <a name="input_aws_api_handler_lambda_invoke_arn"></a> [aws\_api\_handler\_lambda\_invoke\_arn](#input\_aws\_api\_handler\_lambda\_invoke\_arn) | The invoke\_arn uri of the apiHandler service lambda | `string` | `""` | no |
| <a name="input_aws_partner_profile_lambda_arn"></a> [aws\_partner\_profile\_lambda\_arn](#input\_aws\_partner\_profile\_lambda\_arn) | The ARN of the partner\_profile service lambda | `string` | `""` | no |
| <a name="input_aws_partner_profile_lambda_function_name"></a> [aws\_partner\_profile\_lambda\_function\_name](#input\_aws\_partner\_profile\_lambda\_function\_name) | The function name of the partner\_profile service lambda | `string` | `""` | no |
| <a name="input_aws_partner_profile_lambda_invoke_arn"></a> [aws\_partner\_profile\_lambda\_invoke\_arn](#input\_aws\_partner\_profile\_lambda\_invoke\_arn) | The ARN of the PartnerProfile service lambda | `string` | `""` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region | `string` | `"us-west-2"` | no |
| <a name="input_calculate_income_http_method"></a> [calculate\_income\_http\_method](#input\_calculate\_income\_http\_method) | HTTP Method for the calculate\_income request to be handled. Will be assigned to the integrtation route | `string` | `""` | no |
| <a name="input_calculate_income_integration_description"></a> [calculate\_income\_integration\_description](#input\_calculate\_income\_integration\_description) | Description of the gateway integration for the calculate\_income route | `string` | `""` | no |
| <a name="input_calculate_income_path"></a> [calculate\_income\_path](#input\_calculate\_income\_path) | The HTTP Route path associated with calculate\_income\_path | `string` | `""` | no |
| <a name="input_disable_layers"></a> [disable\_layers](#input\_disable\_layers) | Disable lambda layers if true | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The domain name associated with the aws\_route53\_zone for the api\_zone\_resource | `string` | `""` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment being deployed | `string` | `""` | no |
| <a name="input_honeybadger_force_report_data"></a> [honeybadger\_force\_report\_data](#input\_honeybadger\_force\_report\_data) | The force reporting for development and test environments.<br>    See [Honeybadger for Python: force\_report\_data](https://docs.honeybadger.io/lib/python/) | `bool` | `true` | no |
| <a name="input_informed_analyze_docs_backend_base_url"></a> [informed\_analyze\_docs\_backend\_base\_url](#input\_informed\_analyze\_docs\_backend\_base\_url) | The base url for the analyze\_docs backend. Code will append path for each version | `string` | `""` | no |
| <a name="input_informed_api_pass_thru_backend_base_url"></a> [informed\_api\_pass\_thru\_backend\_base\_url](#input\_informed\_api\_pass\_thru\_backend\_base\_url) | The base url for the informed-api backend other than calcute\_income and analyze\_docs | `string` | `""` | no |
| <a name="input_informed_calculate_income_backend_url"></a> [informed\_calculate\_income\_backend\_url](#input\_informed\_calculate\_income\_backend\_url) | The full url for the informed-api backend | `string` | `""` | no |
| <a name="input_lambda_authorizer_handler"></a> [lambda\_authorizer\_handler](#input\_lambda\_authorizer\_handler) | The handler name for the lambda\_authorizer | `string` | `""` | no |
| <a name="input_lambda_authorizer_runtime"></a> [lambda\_authorizer\_runtime](#input\_lambda\_authorizer\_runtime) | The runtime for the lambda\_authorizer | `string` | `""` | no |
| <a name="input_lambda_bucket_name"></a> [lambda\_bucket\_name](#input\_lambda\_bucket\_name) | Name of S3 bucket to store lambdas | `string` | `""` | no |
| <a name="input_lambda_codeguru_layer_arn"></a> [lambda\_codeguru\_layer\_arn](#input\_lambda\_codeguru\_layer\_arn) | ARN of the lambda AWS CodeGuru Profiler layer | `string` | `""` | no |
| <a name="input_lambda_otel_layer_arn"></a> [lambda\_otel\_layer\_arn](#input\_lambda\_otel\_layer\_arn) | ARN of the lambda otel layer | `string` | `""` | no |
| <a name="input_partner_profile_integration_description"></a> [partner\_profile\_integration\_description](#input\_partner\_profile\_integration\_description) | Description of the gateway integration for the parnter\_profile route | `string` | `""` | no |
| <a name="input_partner_profile_path"></a> [partner\_profile\_path](#input\_partner\_profile\_path) | The HTTP Route path associated with partner\_profile | `string` | `""` | no |
| <a name="input_partner_profiles_path"></a> [partner\_profiles\_path](#input\_partner\_profiles\_path) | The HTTP Route path associated with partner\_profiles | `string` | `""` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | State Name of the API Gateway | `string` | `""` | no |

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
