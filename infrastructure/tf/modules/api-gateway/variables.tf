variable "lambda_bucket_name" {
  description = "Name of S3 bucket to store lambdas"
  type        = string
  default     = ""
}

variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = ""
}

variable "api_gateway_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "State Name of the API Gateway"
  type        = string
  default     = ""
}

variable "api_gateway_domain_name" {
  description = "Domain Name to assign to the API Gateway and its TLS Certificate"
  type        = string
  default     = ""
}

variable "alternative_names" {
  description = "Alternative DNS names for the Certificate"
  type        = list(string)
  default     = []
}


variable "calculate_income_integration_description" {
  description = "Description of the gateway integration for the calculate_income route"
  type        = string
  default     = ""
}

variable "api_pass_thru_integration_description" {
  description = "Description of the gateway integration for api routes other than calculate_income and analyze_docs"
  type        = string
  default     = ""
}

variable "analyze_docs_integration_description" {
  description = "Description of the gateway integration for the analyze_docs route"
  type        = string
  default     = ""
}

variable "partner_profile_integration_description" {
  description = "Description of the gateway integration for the parnter_profile route"
  type        = string
  default     = ""
}

variable "api_handler_integration_description" {
  description = "Description of the gateway integration for the api_handler route"
  type        = string
  default     = ""
}

variable "calculate_income_http_method" {
  description = "HTTP Method for the calculate_income request to be handled. Will be assigned to the integrtation route"
  type        = string
  default     = ""
}

variable "calculate_income_path" {
  description = "The HTTP Route path associated with calculate_income_path"
  type        = string
  default     = ""
}

variable "partner_profile_path" {
  description = "The HTTP Route path associated with partner_profile"
  type        = string
  default     = ""
}

variable "partner_profiles_path" {
  description = "The HTTP Route path associated with partner_profiles"
  type        = string
  default     = ""
}

variable "applications_path" {
  description = "The HTTP Route path associated with api-handler applications"
  type        = string
  default     = ""
}

variable "authorization_lambda_name" {
  description = "Name of the custom authorizer Lambda"
  type        = string
  default     = ""
}

variable "authorizer_name" {
  description = "Name to be associated with the aws_apigatewayv2_authorizer"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "The domain name associated with the aws_route53_zone for the api_zone_resource"
  type        = string
  default     = ""
}

variable "environment" {
  description = "The environment being deployed"
  type        = string
  default     = ""
}

variable "informed_calculate_income_backend_url" {
  description = "The full url for the informed-api backend"
  type        = string
  default     = ""
}

variable "informed_api_pass_thru_backend_base_url" {
  description = "The base url for the informed-api backend other than calcute_income and analyze_docs"
  type        = string
  default     = ""
}

variable "analyze_docs_versions" {
  description = "The versions used for analyze docs routes"
  type        = list(any)
  default     = []
}

variable "informed_analyze_docs_backend_base_url" {
  description = "The base url for the analyze_docs backend. Code will append path for each version"
  type        = string
  default     = ""
}

variable "lambda_authorizer_handler" {
  description = "The handler name for the lambda_authorizer"
  type        = string
  default     = ""
}

variable "lambda_authorizer_runtime" {
  description = "The runtime for the lambda_authorizer"
  type        = string
  default     = ""
}

variable "lambda_otel_layer_arn" {
  description = "ARN of the lambda otel layer "
  type        = string
  default     = ""
}

variable "lambda_codeguru_layer_arn" {
  description = "ARN of the lambda AWS CodeGuru Profiler layer "
  type        = string
  default     = ""
}


variable "authorizer_honeybadger_api_key" {
  description = "The api key for sending data to honeybadger for the authorizer"
  type        = string
  default     = ""
}

variable "honeybadger_force_report_data" {
  description = <<EOF
    The force reporting for development and test environments.
    See [Honeybadger for Python: force_report_data](https://docs.honeybadger.io/lib/python/)
EOF
  type        = bool
  default     = true
}

variable "aws_partner_profile_lambda_invoke_arn" {
  description = "The ARN of the PartnerProfile service lambda"
  type        = string
  default     = ""
}

variable "aws_api_handler_lambda_invoke_arn" {
  description = "The invoke_arn uri of the apiHandler service lambda"
  type        = string
  default     = ""
}

variable "aws_api_handler_lambda_function_name" {
  description = "The function name of the apiHandler service lambda"
  type        = string
  default     = ""
}

variable "aws_partner_profile_lambda_arn" {
  description = "The ARN of the partner_profile service lambda"
  type        = string
  default     = ""
}

variable "aws_partner_profile_lambda_function_name" {
  description = "The function name of the partner_profile service lambda"
  type        = string
  default     = ""
}

variable "disable_layers" {
  description = "Disable lambda layers if true"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = ""
}
