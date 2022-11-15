locals {
  scope_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_sqs_queue" "eventbridge_deadletter" {
  name = "${local.scope_prefix}-eventbridge-deadletter"
}

data "aws_iam_policy" "eventbridge_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
}

module "custom_eventbus" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "1.14.2"

  bus_name                 = local.scope_prefix
  role_name                = "${local.scope_prefix}-eventbridge-role-${data.aws_region.current.name}"
  attach_policy            = true
  policy                   = data.aws_iam_policy.eventbridge_full_access.arn
  attach_cloudwatch_policy = var.eventbridge_create_api_destinations
  attach_sqs_policy        = var.eventbridge_create_api_destinations
  sqs_target_arns          = [aws_sqs_queue.eventbridge_deadletter.arn]
  cloudwatch_target_arns   = [aws_cloudwatch_log_group.all-eventbridge.arn]

  rules = {
    all-events-to-cloudwatch = {
      event_pattern = jsonencode({
        "account" : [data.aws_caller_identity.current.account_id]
      })
      destination = jsonencode({
        cloudwatch_logs = {
          log_group_name = "${local.scope_prefix}-all-eventbridge-logs"
        }
      })
    }
  }
  targets = {
    all-events-to-cloudwatch = [
      {
        name = "${local.scope_prefix}-all-events-to-cloudwatch.arn"
        arn  = aws_cloudwatch_log_group.all-eventbridge.arn
      }
    ]
  }
}

resource "aws_schemas_discoverer" "custom_eventbus" {
  source_arn  = module.custom_eventbus.eventbridge_bus_arn
  description = "Auto discover event schemas"
}

resource "aws_cloudwatch_log_group" "all-eventbridge" {
  name = "/aws/events/${local.scope_prefix}-all-eventbridge-logs"
}

module "eventbridge_upload_bucket" {
  source                        = "terraform-aws-modules/eventbridge/aws"
  version                       = "1.14.1"
  create_bus                    = false
  create_role                   = false
  create_connections            = var.eventbridge_create_api_destinations
  create_api_destinations       = var.eventbridge_create_api_destinations
  create_targets                = var.eventbridge_create_api_destinations
  attach_api_destination_policy = var.eventbridge_create_api_destinations

  # rules = {
  #   "${local.scope_prefix}_input_file_received" = {
  #     description = "Rule for input_file_received event with webhook"
  #     event_pattern = jsonencode({
  #       "source" : ["aws.s3"],
  #       "detail-type" : ["Object Created"],
  #       "detail" : {
  #         "bucket" : {
  #           "name" : [module.upload_bucket.bucket_id]
  #         }
  #       }
  #     })
  #   }
  # }

  targets = {
    "${local.scope_prefix}_input_file_received" = [
      {
        name            = "${local.scope_prefix}_input_file_received_webhook"
        destination     = "${local.scope_prefix}_input_file_received_webhook"
        attach_role_arn = module.custom_eventbus.eventbridge_role_arn
        dead_letter_arn = aws_sqs_queue.eventbridge_deadletter.arn
      },
      {
        name            = "${local.scope_prefix}-techno-core-eventbridge"
        arn             = module.custom_eventbus.eventbridge_bus_arn
        attach_role_arn = module.custom_eventbus.eventbridge_role_arn
        dead_letter_arn = aws_sqs_queue.eventbridge_deadletter.arn
      }
    ]
  }

  connections = {
    "${local.scope_prefix}_input_file_received_webhook" = {
      authorization_type = "API_KEY"
      auth_parameters = {
        api_key = {
          key   = "X_CUSTOM_AUTH"
          value = data.aws_ssm_parameter.auth_value.value
        }
      }
    }
  }

  # api_destinations = {
  #   "${local.scope_prefix}_input_file_received_webhook" = {
  #     description                      = "The ${var.environment} input_file_received Adapter"
  #     invocation_endpoint              = "https://api-internal.${var.environment}.${var.dns_base_domain}/v1/event_hook/input_file_received"
  #     http_method                      = "POST"
  #     invocation_rate_limit_per_second = 20
  #   }
  # }
}
