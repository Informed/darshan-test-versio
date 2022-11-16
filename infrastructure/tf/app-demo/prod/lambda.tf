data "aws_s3_bucket" "upload_bucket" {
  bucket = "informed-techno-core-${var.environment}-uploads"
}

data "aws_s3_bucket" "exchange_bucket" {
  bucket = "informed-techno-core-${var.environment}-exchange"
}

data "aws_ssm_parameter" "api_gateway_api_id" {
  name = "/tc/platform/api_gateway/api_gateway_api_id"
}

data "aws_ssm_parameter" "authorizer_id" {
  name = "/tc/platform/api_gateway/authorizer_id"
}

data "aws_apigatewayv2_api" "api_gateway" {
  api_id = data.aws_ssm_parameter.api_gateway_api_id.value
}

#####################
## Lambda function ##
#####################

data "aws_iam_policy_document" "app_demo_lambda_permissions" {
  statement {
    sid     = "DynamodbAccess"
    effect  = "Allow"
    actions = ["dynamodb:*"]
    resources = [
      "*"
    ]
  }
  statement {
    sid       = "EventBridgeAccess"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = ["*"]
  }
  statement {
    sid    = "ParameterStoreRead"
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:GetParametersByPath"
    ]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/tc/${var.environment}/*"]
  }
  statement {
    sid    = "OtelPermissions"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries",
      "ssm:GetParameters"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "InokeLambda"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:techno-core-${var.environment}-partner-profile"
    ]
  }
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

module "app_demo_lambda_function" {
  # tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/informed/borg.git//aws-lambda"

  # function configuration
  function_name  = "${var.project_name}-${var.environment}-app-demo"
  handler        = var.lambda_handler_name
  runtime        = var.runtime
  architectures  = var.architectures
  tracing_mode   = var.lambda_tracing_mode
  timeout        = var.timeout
  memory_size    = var.memory_size
  create_package = false
  s3_existing_package = {
    bucket = "iq-artifacts-cicd-uswest2"
    key    = "${var.environment}/app_demo/latest.zip"
  }
  #layers = var.layer_arns
  environment_variables = merge(
    {
      "LOG_LEVEL"                           = var.log_level
      "AWS_LAMBDA_EXEC_WRAPPER"             = "/opt/otel-instrument"
      "OPENTELEMETRY_COLLECTOR_CONFIG_FILE" = "/var/task/app/config/${var.environment}_otel_collector.yaml"
      "HONEYBADGER_API_KEY"                 = var.app_demo_honeybadger_api_key
      "HONEYBADGER_ENVIRONMENT"             = var.environment
      "HONEYBADGER_FORCE_REPORT_DATA"       = var.honeybadger_force_report_data
      "Environment"                         = var.environment
      "AWS_UPLOADS_BUCKET"                  = data.aws_s3_bucket.upload_bucket.id
      "AWS_DEFAULT_BUCKET"                  = data.aws_s3_bucket.exchange_bucket.id
      "APPLICATION_ORCHESTRATOR_ENDPOINT"   = "https://api-internal.${var.environment}.informediq-infra.com"
    },
    var.extra_environment_variables
  )


  # triggers
  create_current_version_allowed_triggers = false # disables function version invokation restriction
  allowed_triggers = {
    APIGateway = {
      principal  = "apigateway.amazonaws.com"
      source_arn = "${data.aws_apigatewayv2_api.api_gateway.execution_arn}/*/*/*"
    }
  }

  # lambda role
  role_name          = "${var.project_name}-${var.environment}-app-demo"
  role_description   = "used for ${var.project_name}-${var.environment}-app-demo function"
  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.app_demo_lambda_permissions.json
}

##############################
## API Gateway Integrations ##
##############################

# resource "aws_apigatewayv2_route" "app_demo_post_applications" {
#   api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
#   route_key          = "POST /v1/auto/applications"
#   target             = "integrations/${aws_apigatewayv2_integration.app_demo.id}"
#   authorization_type = "CUSTOM"
#   authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
# }

# resource "aws_apigatewayv2_route" "app_demo_get_applications" {
#   api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
#   route_key          = "GET /v1/auto/applications"
#   target             = "integrations/${aws_apigatewayv2_integration.app_demo.id}"
#   authorization_type = "CUSTOM"
#   authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
# }

# resource "aws_apigatewayv2_route" "app_demo_put_applications_by_id" {
#   api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
#   route_key          = "PUT /v1/auto/applications/{applicationId}"
#   target             = "integrations/${aws_apigatewayv2_integration.app_demo.id}"
#   authorization_type = "CUSTOM"
#   authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
# }

# resource "aws_apigatewayv2_route" "app_demo_get_applications_by_id" {
#   api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
#   route_key          = "GET /v1/auto/applications/{applicationId}"
#   target             = "integrations/${aws_apigatewayv2_integration.app_demo.id}"
#   authorization_type = "CUSTOM"
#   authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
# }

# resource "aws_apigatewayv2_route" "app_demo_get_documents_by_application_id" {
#   api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
#   route_key          = "GET /v1/auto/applications/{applicationId}/documents"
#   target             = "integrations/${aws_apigatewayv2_integration.app_demo.id}"
#   authorization_type = "CUSTOM"
#   authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
# }

# resource "aws_apigatewayv2_route" "app_demo_post_documents_by_application_id" {
#   api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
#   route_key          = "POST /v1/auto/applications/{applicationId}/documents"
#   target             = "integrations/${aws_apigatewayv2_integration.app_demo.id}"
#   authorization_type = "CUSTOM"
#   authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
# }

# resource "aws_apigatewayv2_route" "app_demo_put_documents_by_application_id_and_document_id" {
#   api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
#   route_key          = "PUT /v1/auto/applications/{applicationId}/documents/{documentId}"
#   target             = "integrations/${aws_apigatewayv2_integration.app_demo.id}"
#   authorization_type = "CUSTOM"
#   authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
# }

# resource "aws_apigatewayv2_route" "app_demo_post_documents_collect_by_application_id" {
#   api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
#   route_key          = "POST /v1/auto/applications/{applicationId}/documents/collect"
#   target             = "integrations/${aws_apigatewayv2_integration.app_demo.id}"
#   authorization_type = "CUSTOM"
#   authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
# }

# resource "aws_apigatewayv2_integration" "app_demo" {
#   api_id                 = data.aws_ssm_parameter.api_gateway_api_id.value
#   integration_type       = "AWS_PROXY"
#   connection_type        = "INTERNET"
#   description            = "Pass thru to apiHandler Service"
#   integration_method     = "POST"
#   payload_format_version = "2.0"
#   integration_uri        = module.app_demo_lambda_function.lambda_function_invoke_arn
#   request_parameters = {
#     "append:header.OTEL_INFO"   = "$context.authorizer.otel_info"
#     "append:header.JWT"         = "$context.authorizer.jwt"
#     "append:header.TRACEPARENT" = "$context.authorizer.traceparent"
#   }
# }
