# TODO: Add support for dynamodb_table_config
# variable "dynamodb_table_config" {
#   description = <<EOF
#   DynamoDB table configuration
#   Allows to specify the table name, and all other dynamodb table configurations other than Global Secondary Indexes.
#   It is a map of maps.
#     Each top level map has the table name as key and a map of configuration and attributes.
#       The Configuration is a map where the keys are the variables for this module other than attriubtes and Global Secondary Indexes
#       The Attributes is a map where the keys are attribute name and the value is the type of the attribute.

#   dynmaic_table_config = {
#     table0 = {
#       configs = {
#         hash_key = "PK",
#         range_key = "SK",
#         billing_mode = "PAY_PER_REQUEST",
#         server_side_encryption = true,
#         point_in_time_recovery = true,
#       },
#       attributes = {
#         PK = "S",
#         SK = "S",
#         gsi1pk = "S",
#         gsi2pk = "S",
#       },
#     }

#   }
# EOF
#   type = map(
#     object({
#       configs    = map(map(string)),
#       attributes = map(map(string)),
#   }))
# }

variable "dynamodb_name" {
  description = "Name of the DynamoDb Table. Should be snake_case"
  type        = string
  default     = ""
}

variable "billing_mode" {
  description = "Billing mode for the DynamoDb Table"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "server_side_encryption" {
  description = <<EOF
  Server side encryption key selection for the DynamoDb Table

  enabled == false -> use AWS Owned CMK
  enabled == true -> use AWS Managed CMK
  enabled == true + kms_key_arn is set -> use custom key
EOF
  type = object({
    enabled     = bool,
    kms_key_arn = string
  })
  default = {
    enabled     = false,
    kms_key_arn = ""
  }
}

variable "point_in_time_recovery" {
  description = "Point in time recovery for the DynamoDb Table"
  type        = bool
  default     = true
}

variable "hash_key" {
  description = "Hash key for the DynamoDb Table"
  type = object({
    name = string
    type = string
  })
  default = {
    name = "PK",
    type = "S"
  }
}


variable "range_key" {
  description = "Range key for the DynamoDb Table"
  type = object({
    name = string
    type = string
  })
  default = {
    name = "SK",
    type = "S"
  }
}

# Todo: Add support for global secondary indexes
# variable "secondary_indexes" {
#   description = <<EOF
#   Secondary indexes for the DynamoDb Table.
#   If you do not specify this, the table will not have any secondary indexes.
#   You must specify the hash_keys & rang_keys name and type as attributes in the parent table defintion

#   Example:
#   secondary_indexes = {
#       gsiName0 = {hash_key = "gsi1pk",
#                   range_key = "SK",
#                   projection_type = "ALL"},
#       gsiName1 = {hash_key = "gsi2pk",
#                   range_key = "SK",
#                   projection_type = "ALL"}
#   }
# EOF
#   type        = map(map(string))
#   default     = {}
# }
