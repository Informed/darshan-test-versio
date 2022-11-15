variable "bucket_base_name" {
  description = "The base name of the S3 bucket"
  type        = string
  default     = ""
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

variable "cors_rule_inputs" {
  description = "CORS rule inputs"
  type = list(object({
    allowed_methods = list(string),
    allowed_origins = list(string),
    allowed_headers = list(string),
    expose_headers  = list(string),
    max_age_seconds = number
  }))
  default = []
}

variable "privileged_principal_arns" {
  description = <<EOF
  Privileged principal arns

  List of maps with the following:
  - Key: arn of the role or user to grant access to the bucket
  - Value: a list of the actions to grant to the role or user

  Example:
  [
    {"arn:aws:iam::123456789012:role/lambda-role" = ["*/*/app_request/"]},
    {"arn:aws:iam::123456789012:user/lambda-user" = ["*/*/app_request/"]}
  ]
EOF
  type        = list(map(list(string)))
  default     = []
}

variable "privileged_principal_actions" {
  description = "Privileged principal actions"
  type        = list(string)
  default     = []
}

variable "eventbridge_enable" {
  description = "Enable EventBridge"
  type        = bool
  default     = false
}

variable "log_storage_bucket_id" {
  description = "Name/ID of the bucket to hold access logs"
  type        = string
  default     = ""
}

variable "log_storage_bucket_prefix" {
  description = "Prefix for the log bucket"
  type        = string
  default     = ""
}
