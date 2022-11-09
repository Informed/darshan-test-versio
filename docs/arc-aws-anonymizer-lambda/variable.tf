variable "environment" {
  description = "Name of this environment"
  type        = string
}

variable "region" {
  description = "Region to deploy terraform resources to"
  type        = string
  default     = "us-west-2"
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "profile" {
  description = "AWS profile to use"
  type        = string
}

variable "source_bucket" {
  description="backend key"
  type= string
}

variable "destination_bucket" {
  description="dynamodb table"
  type= string
}
