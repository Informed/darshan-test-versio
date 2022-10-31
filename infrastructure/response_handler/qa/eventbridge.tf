##
## These are events that originate from the legacy services
##

locals {
  scope_prefix = "${var.project_name}-${var.environment}"
}

data "aws_sqs_queue" "eventbridge_deadletter" {
  name = "${local.scope_prefix}-eventbridge-deadletter"
}

module "eventbridge_legacy_events" {
  source         = "terraform-aws-modules/eventbridge/aws"
  version        = "1.14.1"
  bus_name       = local.scope_prefix
  create_bus     = false
  create_role    = false
  create_targets = true

  rules = {
    "${local.scope_prefix}_stipulation_verification_complete" = {
      description   = "Rule for stipulation_verification_complete"
      event_pattern = jsonencode({ "source" : ["applicationOrchestrator"], "detail-type" : ["StipulationVerificationComplete"] })
      enabled       = true
    }
    "${local.scope_prefix}_inputFile_extraction_complete" = {
      description   = "Rule for inputFile_extraction_complete"
      event_pattern = jsonencode({ "source" : ["applicationOrchestrator"], "detail-type" : ["DocumentsExtractionComplete"] })
      enabled       = true
    }
  }

  targets = {
    "${local.scope_prefix}_stipulation_verification_complete" = [
      {
        name            = "${local.scope_prefix}_stipulation_verification_complete"
        arn             = module.response_handler_lambda_function.lambda_function_arn
        dead_letter_arn = data.aws_sqs_queue.eventbridge_deadletter.arn
      }
    ]
    "${local.scope_prefix}_inputFile_extraction_complete" = [
      {
        name            = "${local.scope_prefix}_inputFile_extraction_complete"
        arn             = module.response_handler_lambda_function.lambda_function_arn
        dead_letter_arn = data.aws_sqs_queue.eventbridge_deadletter.arn
      }
    ]
  }
}

resource "aws_lambda_permission" "stipulation_verification_complete_invoke_response_handler" {
  statement_id  = "AllowEventStipulationVerificationCompleteInvokeResponseHandler"
  action        = "lambda:InvokeFunction"
  function_name = module.response_handler_lambda_function.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge_legacy_events.eventbridge_rule_arns["${local.scope_prefix}_stipulation_verification_complete"]
}

resource "aws_lambda_permission" "inputFile_extraction_complete_invoke_response_handler" {
  statement_id  = "AllowinputFileExtractionCompleteInvokeResponseHandler"
  action        = "lambda:InvokeFunction"
  function_name = module.response_handler_lambda_function.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge_legacy_events.eventbridge_rule_arns["${local.scope_prefix}_inputFile_extraction_complete"]
}
