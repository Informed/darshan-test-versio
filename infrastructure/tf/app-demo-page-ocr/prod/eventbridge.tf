##
## These are events that originate from the legacy services
##

locals {
  scope_prefix = "${var.project_name}-${var.environment}"
}

data "aws_sqs_queue" "eventbridge_deadletter" {
  name = "${local.scope_prefix}-eventbridge-deadletter"
}

module "eventbridge_events" {
  source         = "terraform-aws-modules/eventbridge/aws"
  version        = "1.14.1"
  bus_name       = local.scope_prefix
  create_bus     = false
  create_role    = false
  create_targets = true

  rules = {
    "${local.scope_prefix}_image_process_start" = {
      description   = "Rule for image_process_start"
      event_pattern = jsonencode({ "source" : ["imageConverter"], "detail-type" : ["ImageProcessStart"] })
      enabled       = true
    }
  }

  targets = {
    "${local.scope_prefix}_image_process_start" = [
      {
        name            = "${local.scope_prefix}_image_process_start"
        arn             = module.app_demo_page_ocr_lambda_function.lambda_function_arn
        dead_letter_arn = data.aws_sqs_queue.eventbridge_deadletter.arn
      }
    ]
  }
}

resource "aws_lambda_permission" "image_process_start_invoke_app_demo_page_ocr" {
  statement_id  = "AllowEventImageProcessStartInvokeAppDemoPageOcr"
  action        = "lambda:InvokeFunction"
  function_name = module.app_demo_page_ocr_lambda_function.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge_events.eventbridge_rule_arns["${local.scope_prefix}_image_process_start"]
}
