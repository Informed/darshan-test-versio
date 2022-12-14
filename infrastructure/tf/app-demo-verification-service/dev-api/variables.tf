variable "region" {
  description = "The region to deploy terraform resources into"
  type        = string
  default     = "us-west-2"
}

variable "profile" {
  description = "The profile to use for deploying resources"
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

variable "app_demo_verification_service_honeybadger_api_key" {
  description = "API Key for Verification Service Honeybadger access"
  type        = string
  default     = "hbp_FF5VWoO86GE0S069k7J0CnzWlgeDO81QXrYx"
}

variable "honeybadger_force_report_data" {
  description = <<EOF
    The force reporting for development and test environments.
    See [Honeybadger for Python: force_report_data](https://docs.honeybadger.io/lib/python/)
EOF
  type        = bool
  default     = true
}

variable "disable_layers" {
  description = "Disable lambda layers if true"
  type        = bool
  default     = true
}

variable "log_level" {
  description = "Log level for the lambda functions"
  type        = string
  default     = "INFO"
}

variable "runtime" {
  description = "lambda runtime to use"
  type        = string
  default     = "ruby2.7"
}

variable "architectures" {
  description = "lambda architecture to use"
  type        = list(string)
  default     = ["x86_64"]
}

variable "timeout" {
  description = "lambda timeout to use"
  type        = string
  default     = "900"
}

variable "memory_size" {
  description = "lambda memory size to use"
  type        = string
  default     = "512"
}

variable "layer_arns" {
  description = "List of otel layer arns"
  type        = list(string)
  default = []
}

variable "lambda_handler_file" {
  description = "lambda handler zip file to use"
  type        = string
  default     = "app_demo_verification_service.zip"
}

variable "lambda_handler_name" {
  description = "lambda handler to call"
  type        = string
  default     = "app_demo_verification_service"
}

variable "lambda_tracing_mode" {
  description = "lambda tracing mode to use"
  type        = string
  default     = "Active"
}

variable "extra_environment_variables" {
  description = "Extra environment variables to set"
  type        = map(string)
  default     = {}
}
