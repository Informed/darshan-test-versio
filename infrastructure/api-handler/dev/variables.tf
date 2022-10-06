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

variable "api_handler_honeybadger_api_key" {
  description = "API Key for API Handler Honeybadger access"
  type        = string
  default     = "hbp_2xj5epE6rHbEgxxkw95dDSQ5O4iESx3F6GDE"
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
  default     = false
}

variable "log_level" {
  description = "Log level for the lambda functions"
  type        = string
  default     = "INFO"
}

variable "region" {
  description = "Region to deploy terraform resources to"
  type        = string
  default     = "us-west-2"
}

variable "profile" {
  description = "AWS profile to use"
  type        = string
}

variable "runtime" {
  description = "lambda runtime to use"
  type        = string
  default     = "python3.8"
}

variable "architectures" {
  description = "lambda architecture to use"
  type        = list(string)
  default     = ["x86_64"]
}

variable "timeout" {
  description = "lambda timeout to use"
  type        = string
  default     = "60"
}

variable "memory_size" {
  description = "lambda memory size to use"
  type        = string
  default     = "512"
}

variable "layer_arns" {
  description = "List of otel layer arns"
  type        = list(string)
  default = [
    "arn:aws:lambda:us-west-2:901920570463:layer:aws-otel-python-amd64-ver-1-11-1:2",
  ]
}

variable "lambda_handler_file" {
  description = "lambda handler zip file to use"
  type        = string
  default     = "api_handler.zip"
}

variable "lambda_handler_name" {
  description = "lambda handler to call"
  type        = string
  default     = "api_handler.handler"
}

variable "lambda_tracing_mode" {
  description = "lambda tracing mode to use"
  type        = string
  default     = "Active"
}

variable "extra_environment_variables" {
  description = "Extra environment variables to set.extra asd"
  type        = map(string)
  default     = {}
}
