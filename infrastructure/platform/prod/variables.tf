variable "dns_base_domain" {
  description = "Base domain for the target domainnames"
  type        = string
}

variable "bucket_prefix" {
  description = "Prefix for Buckets"
  type        = string
  default     = "informed"
}

variable "project_name" {
  description = "Name of Project"
  type        = string
  default     = "techno"
}

variable "environment" {
  description = "Name of this environment"
  type        = string
}

variable "authorizer_honeybadger_api_key" {
  description = "API Key for Honeybadger access for Authorizer"
  type        = string
  default     = "hbp_qu0Y7vf1gSFxZj5tEdAUX87QGnyCSa0TmrMp"
}

variable "api_handler_honeybadger_api_key" {
  description = "API Key for API Handler Honeybadger access"
  type        = string
  default     = "hbp_2xj5epE6rHbEgxxkw95dDSQ5O4iESx3F6GDE"
}

variable "response_handler_honeybadger_api_key" {
  description = "API Key for Response Handler Honeybadger access"
  type        = string
  default     = "hbp_YoGxhMGnep5z81s27sJkfF4QrYyK5b14iaqC"
}

variable "partner_profile_honeybadger_api_key" {
  description = "API Key for Partner Profile Honeybadger access"
  type        = string
  default     = "hbp_PRwWENiasCPczk1r70XXFQ3dJEQCN52K6FWc"
}

variable "honeybadger_force_report_data" {
  description = <<EOF
    The force reporting for development and test environments.
    See [Honeybadger for Python: force_report_data](https://docs.honeybadger.io/lib/python/)
EOF
  type        = bool
  default     = true
}

variable "informed_analyze_docs_backend_base_url" {
  description = "Preprocessor link for analyze docs"
  type        = string
}

variable "eventbridge_create_api_destinations" {
  description = "Should create the eventbridge api-destinations. Only false for when the target destination hasnt been built yet due to legacy code work"
  type        = bool
  default     = true
}

variable "disable_layers" {
  description = "Disable lambda layers if true"
  type        = bool
  default     = false
}

variable "additional_exchange_bucket_privileged_principal_arns" {
  description = <<EOF
  Additional exchange bucket privileged principal arns

  List of maps with the following:
  - Key: arn of the role or user to grant access to the bucket
  - Value: a list of the actions to grant to the role or user

  These will be concatinated to the existing list of privileges in main.tf

  Example:
  [
    {"arn:aws:iam::123456789012:role/lambda-role" = ["*/*/app_request/"]},
    {"arn:aws:iam::123456789012:user/lambda-user" = ["*/*/app_request/"]}
  ]
EOF
  type        = list(map(list(string)))
  default     = []
}

variable "additional_upload_bucket_privileged_principal_arns" {
  description = <<EOF
  Additional upload bucket privileged principal arns

  List of maps with the following:
  - Key: arn of the role or user to grant access to the bucket
  - Value: a list of the actions to grant to the role or user

  These will be concatinated to the existing list of privileges in main.tf

  Example:
  [
    {"arn:aws:iam::123456789012:role/lambda-role" = ["*/*/app_request/"]},
    {"arn:aws:iam::123456789012:user/lambda-user" = ["*/*/app_request/"]}
  ]
EOF
  type        = list(map(list(string)))
  default     = []
}

variable "additional_download_bucket_privileged_principal_arns" {
  description = <<EOF
  Additional download bucket privileged principal arns

  List of maps with the following:
  - Key: arn of the role or user to grant access to the bucket
  - Value: a list of the actions to grant to the role or user

  These will be concatinated to the existing list of privileges in main.tf

  Example:
  [
    {"arn:aws:iam::123456789012:role/lambda-role" = ["*/*/app_request/"]},
    {"arn:aws:iam::123456789012:user/lambda-user" = ["*/*/app_request/"]}
  ]
EOF
  type        = list(map(list(string)))
  default     = []
}

variable "log_level" {
  description = "Log level for the lambda functions"
  type        = string
  default     = "INFO"
}

variable "region" {
  description = "The region to deploy terraform resources into"
  type        = string
  default     = "us-west-2"
}

variable "profile" {
  description = "The profile to use for deploying resources"
  type        = string
}

#########
## VPC ##
#########

variable "single_nat_gateway" {
  description = "Whether to have one nat gateway for all non-public subnets or one per subnet"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "The VPC CIDR to use depending upon the environment"
  type        = string
}

variable "authorizer_layer_arns" {
  description = "ARN of the layers to add"
  type        = list(string)
  default = [
    "arn:aws:lambda:us-west-2:901920570463:layer:aws-otel-python-amd64-ver-1-11-1:2",
  ]
}

variable "authorizer_runtime" {
  description = "lambda runtime to use"
  type        = string
  default     = "python3.8"
}

variable "authorizer_architectures" {
  description = "lambda architecture to use"
  type        = list(string)
  default     = ["x86_64"]
}

variable "authorizer_timeout" {
  description = "lambda timeout to use"
  type        = string
  default     = "30"
}

variable "authorizer_memory_size" {
  description = "lambda memory size to use"
  type        = string
  default     = "3072"
}

variable "authorizer_handler" {
  description = "lambda handler to use"
  type        = string
  default     = "partner_authorizer.handler"
}

variable "authorizer_tracing_mode" {
  description = "lambda tracing mode to use"
  type        = string
  default     = "Active"
}

variable "authorizer_extra_environment_variables" {
  description = "Additional / override Authorizer lambda environment variables"
  type        = map(string)
  default     = {}
}
