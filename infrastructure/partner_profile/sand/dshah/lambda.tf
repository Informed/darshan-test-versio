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

data "aws_iam_policy_document" "partner_profile_lambda_permissions" {
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

resource "aws_s3_bucket_object" "object" {

  bucket = "informed-techno-core-${var.environment}-lambda-images"
  key    = var.lambda_handler_file
  acl    = "private" # or can be "public-read"
  source = "../../dummy_lambdas/partner_profile.zip"
}

module "partner_profile_lambda_function" {
  # tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/informed/borg.git//aws-lambda"

  # function configuration
  function_name  = "${var.project_name}-${var.environment}-partner-profile"
  handler        = var.lambda_handler_name
  runtime        = var.runtime
  architectures  = var.architectures
  tracing_mode   = var.lambda_tracing_mode
  timeout        = var.timeout
  memory_size    = var.memory_size
  create_package = false
  s3_existing_package = {
    bucket = "informed-techno-core-${var.environment}-lambda-images"
    key    = var.lambda_handler_file
  }
  layers = var.layer_arns

  environment_variables = merge(
    {
      "LOG_LEVEL"                           = var.log_level
      "AWS_LAMBDA_EXEC_WRAPPER"             = "/opt/otel-instrument"
      "OPENTELEMETRY_COLLECTOR_CONFIG_FILE" = "/var/task/app/config/${var.environment}_otel_collector.yaml"
      "HONEYBADGER_API_KEY"                 = var.partner_profile_honeybadger_api_key
      "HONEYBADGER_ENVIRONMENT"             = var.environment
      "HONEYBADGER_FORCE_REPORT_DATA"       = var.honeybadger_force_report_data
      "Environment"                         = var.environment
    },
    var.extra_environment_variables
  )
  # lambda role
  role_name          = "${var.project_name}-${var.environment}-partner-profile"
  role_description   = "used for ${var.project_name}-${var.environment}-partner-profile function"
  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.partner_profile_lambda_permissions.json

  depends_on = [aws_s3_bucket_object.object]
}

##############################
## API Gateway Integration ##
##############################

resource "aws_apigatewayv2_integration" "partner_profile" {
  api_id                 = data.aws_ssm_parameter.api_gateway_api_id.value
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  description            = "Pass thru to PartnerProfile Service"
  integration_method     = "POST"
  payload_format_version = "2.0"
  integration_uri        = module.partner_profile_lambda_function.lambda_function_invoke_arn
  request_parameters = {
    "append:header.OTEL_INFO"   = "$context.authorizer.otel_info"
    "append:header.JWT"         = "$context.authorizer.jwt"
    "append:header.TRACEPARENT" = "$context.authorizer.traceparent"
  }
}

##############################
## API Gateway Routes
## partner_profile (singular)
##############################

resource "aws_apigatewayv2_route" "partner_profile_by_name" {
  api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
  route_key          = "GET /v1/partner_profile/name/{name}"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profile.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
}

resource "aws_apigatewayv2_route" "partner_profile_service_by_name" {
  api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
  route_key          = "GET /v1/partner_profile/name/{name}/services/metadata"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profile.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
}

resource "aws_apigatewayv2_route" "partner_profile_service_by_email" {
  api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
  route_key          = "GET /v1/partner_profile/email/{email}"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profile.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
}

## These really aren't RESTful, but we're doing it anyway
## Valid queries are:
## ?service=collectiq&subdomain={subdomain}
## ?service=verifyiq&subdomain={subdomain}
resource "aws_apigatewayv2_route" "partner_profile_with_parameters" {
  api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
  route_key          = "GET /v1/partner_profile"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profile.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
}


###############################
## API Gateway Routes
## partner_profiles (plural)
###############################

resource "aws_apigatewayv2_route" "partner_profiles_put" {
  api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
  route_key          = "PUT /v1/partner_profiles/{partnerId}"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profile.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
}

resource "aws_apigatewayv2_route" "partner_profiles_post" {
  api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
  route_key          = "POST /v1/partner_profiles"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profile.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
}

resource "aws_apigatewayv2_route" "partner_profiles_get_by_partner_id" {
  api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
  route_key          = "GET /v1/partner_profiles/{partnerId}"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profile.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
}

resource "aws_apigatewayv2_route" "partner_profiles_get_services_by_partner_id" {
  api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
  route_key          = "GET /v1/partner_profiles/{partnerId}/services/metadata"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profile.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
}

## These really aren't RESTful, but we're doing it anyway
## Valid queries are:
## ?services=metadata
resource "aws_apigatewayv2_route" "partner_profiles_get_services_from_all_profiles" {
  api_id             = data.aws_ssm_parameter.api_gateway_api_id.value
  route_key          = "GET /v1/partner_profiles"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profile.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = data.aws_ssm_parameter.authorizer_id.value
}

##################
## Health Check ##
##################
resource "aws_apigatewayv2_route" "health_check" {
  api_id    = data.aws_ssm_parameter.api_gateway_api_id.value
  route_key = "GET /v1/partner_profile/health_check"
  target    = "integrations/${aws_apigatewayv2_integration.partner_profile.id}"
}

# Enable the Parnter_Profile lambda to be called by the api-gateway
resource "aws_lambda_permission" "partner_profile" {
  statement_id  = "AllowAPIGatewayInvokePartnerProfile"
  action        = "lambda:InvokeFunction"
  function_name = module.partner_profile_lambda_function.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${data.aws_apigatewayv2_api.api_gateway.execution_arn}/*/*/*"
}
