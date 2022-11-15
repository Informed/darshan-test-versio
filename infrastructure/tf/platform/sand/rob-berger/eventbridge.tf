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
