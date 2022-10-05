# TODO: refactor this into separate files for authorizer and api-gateway
# TODO: Delegate the routes to the application modules and not this  module
#
resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = var.lambda_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

resource "aws_lambda_function" "lambda_authorizer" {
  function_name = var.authorizer_name

  filename = "dummy_lambdas/partner_authorizer.zip"
  runtime  = var.lambda_authorizer_runtime
  handler  = var.lambda_authorizer_handler

  memory_size = 3072
  timeout     = 30
  role        = aws_iam_role.lambda_authorizer_exec.arn
  layers = var.disable_layers ? [] : [
    var.lambda_otel_layer_arn,
    var.lambda_codeguru_layer_arn
  ]
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      "AWS_LAMBDA_EXEC_WRAPPER"             = "/opt/otel-instrument"
      "LOG_LEVEL"                           = "INFO"
      "OPENTELEMETRY_COLLECTOR_CONFIG_FILE" = "/var/task/app/config/${var.environment}_otel_collector.yaml"
      "HONEYBADGER_API_KEY"                 = var.authorizer_honeybadger_api_key
      "HONEYBADGER_ENVIRONMENT"             = var.environment
      "HONEYBADGER_FORCE_REPORT_DATA"       = var.honeybadger_force_report_data
      "Environment"                         = var.environment
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_authorizer" {
  name = "/aws/lambda/${aws_lambda_function.lambda_authorizer.function_name}"

  retention_in_days = 30
}

data "aws_iam_policy_document" "lambda_authorizer_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "parameter_store_manager" {
  statement {
    sid = "AuthorizerParameterStoreManager"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = ["arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/tc/${var.environment}/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_role" "lambda_authorizer_exec" {
  name = "${var.api_gateway_name}-authorizer"

  assume_role_policy = data.aws_iam_policy_document.lambda_authorizer_assume_role.json

  inline_policy {
    name   = "${var.environment}-partner-authorizer-parameter-store-manager"
    policy = data.aws_iam_policy_document.parameter_store_manager.json
  }
}

resource "aws_iam_role_policy_attachment" "lambda_authorizer_policy" {
  role       = aws_iam_role.lambda_authorizer_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "codeguru" {
  role       = aws_iam_role.lambda_authorizer_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonCodeGuruProfilerAgentAccess"
}

data "aws_iam_policy_document" "invoke_function" {
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    effect = "Allow"
    resources = [
      var.aws_partner_profile_lambda_arn
    ]
  }
}

# For some reason using aws_iam_role_policy does not work consistently here
resource "aws_iam_policy" "invoke_function" {
  name = "${var.api_gateway_name}-authorizer_invoke_function"

  policy = data.aws_iam_policy_document.invoke_function.json
}

resource "aws_iam_role_policy_attachment" "invoke_function" {
  role       = aws_iam_role.lambda_authorizer_exec.name
  policy_arn = aws_iam_policy.invoke_function.arn
}

data "aws_iam_policy_document" "authorizer_otel_permissions" {
  statement {
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
}
# For some reason using aws_iam_role_policy does not work consistently here
resource "aws_iam_policy" "authorizer-otel-permissions" {
  name = "${var.api_gateway_name}-otel-permissions"

  policy = data.aws_iam_policy_document.authorizer_otel_permissions.json
}

resource "aws_iam_role_policy_attachment" "authorizer-otel-permissions" {
  role       = aws_iam_role.lambda_authorizer_exec.name
  policy_arn = aws_iam_policy.authorizer-otel-permissions.arn
}



# End of Custom Lambda Authorizer
#

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name = "/aws/api-gateway/${var.api_gateway_name}"

  retention_in_days = 30
}


resource "aws_apigatewayv2_api" "api_gateway" {
  name          = var.api_gateway_name
  description   = var.api_gateway_description
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "stage_resource" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = var.stage_name
  auto_deploy = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = <<-EOT
{"requestTime":"$context.requestTime","requestId":"$context.requestId","httpMethod":"$context.httpMethod","path":"$context.path","routeKey":"$context.routeKey","status":$context.status,"responseLatency":$context.responseLatency,"integrationRequestId":"$context.integration.requestId","functionResponseStatus":"$context.integration.status","integrationLatency":"$context.integration.latency","integrationServiceStatus":"$context.integration.integrationStatus","authorizeResultStatus":"$context.authorizer.status","authorizerRequestId":"$context.authorizer.requestId","ip":"$context.identity.sourceIp","userAgent":"$context.identity.userAgent","principalId":"$context.authorizer.principalId"}
EOT
  }
}

# /** Request an SSL certificate */
module "acm_request_certificate" {
  source                            = "cloudposse/acm-request-certificate/aws"
  version                           = "0.16.0"
  domain_name                       = var.api_gateway_domain_name
  subject_alternative_names         = var.alternative_names
  process_domain_validation_options = true
  ttl                               = "300"
  wait_for_certificate_issued       = true
  zone_name                         = var.domain_name
}

resource "aws_apigatewayv2_domain_name" "domain_resource" {
  domain_name = var.api_gateway_domain_name
  domain_name_configuration {
    certificate_arn = module.acm_request_certificate.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}
resource "aws_apigatewayv2_api_mapping" "api_mapping_resource" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  domain_name = aws_apigatewayv2_domain_name.domain_resource.id
  stage       = aws_apigatewayv2_stage.stage_resource.id
}

##
## Calculate Income
##
resource "aws_apigatewayv2_route" "calculate_income" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  route_key          = "${var.calculate_income_http_method} /${var.calculate_income_path}"
  target             = "integrations/${aws_apigatewayv2_integration.calculate_income.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer.id
}

resource "aws_apigatewayv2_integration" "calculate_income" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "HTTP_PROXY"

  connection_type    = "INTERNET"
  description        = var.calculate_income_integration_description
  integration_method = var.calculate_income_http_method
  # This will need to be changed when we hook up real functions
  integration_uri = var.informed_calculate_income_backend_url
  request_parameters = {
    "append:header.OTEL_INFO"     = "$context.authorizer.otel_info"
    "append:header.X-CUSTOM-AUTH" = "eWG9gHQmMRjA3Ub69Bk9hvl8oe9OodBI"
    "append:header.JWT"           = "$context.authorizer.jwt"
    "append:header.TRACEPARENT"   = "$context.authorizer.traceparent"
  }
}

##
## api_pass_thru
##
resource "aws_apigatewayv2_route" "api_pass_thru" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  route_key          = "ANY /api/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.api_pass_thru.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer.id
}

resource "aws_apigatewayv2_integration" "api_pass_thru" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "HTTP_PROXY"

  connection_type    = "INTERNET"
  description        = var.api_pass_thru_integration_description
  integration_method = "ANY"
  integration_uri    = "${var.informed_api_pass_thru_backend_base_url}/api/{proxy}"
  request_parameters = {
    "append:header.OTEL_INFO"     = "$context.authorizer.otel_info"
    "append:header.X-CUSTOM-AUTH" = "eWG9gHQmMRjA3Ub69Bk9hvl8oe9OodBI"
    "append:header.JWT"           = "$context.authorizer.jwt"
    "append:header.TRACEPARENT"   = "$context.authorizer.traceparent"
  }
}

##
## analyze_docs
##
resource "aws_apigatewayv2_route" "analzye_docs" {
  for_each           = toset(var.analyze_docs_versions)
  api_id             = aws_apigatewayv2_api.api_gateway.id
  route_key          = "ANY /api/${each.value}/analyze_docs"
  target             = "integrations/${aws_apigatewayv2_integration.analyze_docs[each.key].id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer.id
}

resource "aws_apigatewayv2_integration" "analyze_docs" {
  for_each         = toset(var.analyze_docs_versions)
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "HTTP_PROXY"

  connection_type    = "INTERNET"
  description        = "${var.analyze_docs_integration_description} for ${each.value}"
  integration_method = "ANY"
  integration_uri    = "${var.informed_analyze_docs_backend_base_url}/api/${each.value}/analyze_docs"
  request_parameters = {
    "append:header.OTEL_INFO"     = "$context.authorizer.otel_info"
    "append:header.X-CUSTOM-AUTH" = "eWG9gHQmMRjA3Ub69Bk9hvl8oe9OodBI"
    "append:header.JWT"           = "$context.authorizer.jwt"
    "append:header.TRACEPARENT"   = "$context.authorizer.traceparent"
  }
}

##
## partner_profile
##
resource "aws_apigatewayv2_route" "partner_profile_query" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  route_key          = "GET /${var.partner_profile_path}"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profile_query.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer.id
}

resource "aws_apigatewayv2_integration" "partner_profile_query" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = var.partner_profile_integration_description
  integration_method     = "POST"
  payload_format_version = "2.0"
  integration_uri        = var.aws_partner_profile_lambda_invoke_arn
  request_parameters = {
    "append:header.OTEL_INFO"   = "$context.authorizer.otel_info"
    "append:header.JWT"         = "$context.authorizer.jwt"
    "append:header.TRACEPARENT" = "$context.authorizer.traceparent"
  }
}

resource "aws_apigatewayv2_route" "partner_profile" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  route_key          = "ANY /${var.partner_profile_path}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profile.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer.id
}

resource "aws_apigatewayv2_integration" "partner_profile" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = var.partner_profile_integration_description
  integration_method     = "POST"
  payload_format_version = "2.0"
  integration_uri        = var.aws_partner_profile_lambda_invoke_arn
  request_parameters = {
    "append:header.OTEL_INFO"   = "$context.authorizer.otel_info"
    "append:header.JWT"         = "$context.authorizer.jwt"
    "append:header.TRACEPARENT" = "$context.authorizer.traceparent"
  }
}

##
## partner_profiles (plural)
##
resource "aws_apigatewayv2_route" "partner_profiles_query" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  route_key          = "ANY /${var.partner_profiles_path}"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profiles_query.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer.id
}

resource "aws_apigatewayv2_integration" "partner_profiles_query" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = var.partner_profile_integration_description
  integration_method     = "POST"
  payload_format_version = "2.0"
  integration_uri        = var.aws_partner_profile_lambda_invoke_arn
  request_parameters = {
    "append:header.OTEL_INFO"   = "$context.authorizer.otel_info"
    "append:header.JWT"         = "$context.authorizer.jwt"
    "append:header.TRACEPARENT" = "$context.authorizer.traceparent"
  }
}

resource "aws_apigatewayv2_route" "partner_profiles" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  route_key          = "ANY /${var.partner_profiles_path}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.partner_profiles.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer.id
}

resource "aws_apigatewayv2_integration" "partner_profiles" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = var.partner_profile_integration_description
  integration_method     = "POST"
  payload_format_version = "2.0"
  integration_uri        = var.aws_partner_profile_lambda_invoke_arn
  request_parameters = {
    "append:header.OTEL_INFO"   = "$context.authorizer.otel_info"
    "append:header.JWT"         = "$context.authorizer.jwt"
    "append:header.TRACEPARENT" = "$context.authorizer.traceparent"
  }
}

##
## Health Check
##
resource "aws_apigatewayv2_route" "health_check" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /${var.partner_profile_path}/health_check"
  target    = "integrations/${aws_apigatewayv2_integration.health_check.id}"
}

resource "aws_apigatewayv2_integration" "health_check" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = var.partner_profile_integration_description
  integration_method     = "POST"
  payload_format_version = "2.0"
  integration_uri        = var.aws_partner_profile_lambda_invoke_arn
  request_parameters = {
    "append:header.OTEL_INFO"   = "$context.authorizer.otel_info"
    "append:header.JWT"         = "$context.authorizer.jwt"
    "append:header.TRACEPARENT" = "$context.authorizer.traceparent"
  }
}

##
## api-handler application
##
resource "aws_apigatewayv2_route" "application" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  route_key          = "ANY /${var.applications_path}/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.applications.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer.id
}

resource "aws_apigatewayv2_route" "application_slash" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  route_key          = "ANY /${var.applications_path}"
  target             = "integrations/${aws_apigatewayv2_integration.applications.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer.id
}

resource "aws_apigatewayv2_integration" "applications" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = var.api_handler_integration_description
  integration_method     = "POST"
  payload_format_version = "2.0"
  integration_uri        = var.aws_api_handler_lambda_invoke_arn
  request_parameters = {
    "append:header.OTEL_INFO"   = "$context.authorizer.otel_info"
    "append:header.JWT"         = "$context.authorizer.jwt"
    "append:header.TRACEPARENT" = "$context.authorizer.traceparent"
  }
}


##
##
resource "aws_apigatewayv2_authorizer" "authorizer" {
  api_id                            = aws_apigatewayv2_api.api_gateway.id
  authorizer_type                   = "REQUEST"
  identity_sources                  = ["$request.header.Authorization"]
  name                              = var.authorizer_name
  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 0
  enable_simple_responses           = false
  authorizer_uri                    = aws_lambda_function.lambda_authorizer.invoke_arn
}

data "aws_route53_zone" "api_zone_resource" {
  name = var.domain_name
}

resource "aws_route53_record" "route53_record_resource" {
  zone_id = data.aws_route53_zone.api_zone_resource.zone_id
  name    = aws_apigatewayv2_domain_name.domain_resource.domain_name
  type    = "CNAME"
  ttl     = "300"
  records = [
    aws_apigatewayv2_domain_name.domain_resource.domain_name_configuration[0].target_domain_name
  ]
}

# TODO: Make this cloudwatch role and policy "global" for all environments?
# This needs to be created just once for all environments in an
# aws account/region But if its removed from here it will be destroyed
# The current scheme assigns a new cloudwatch_role_arn for each environment
resource "aws_api_gateway_account" "api_gateway" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

data "aws_iam_policy_document" "cloudwatch_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_${var.environment}_global"

  assume_role_policy = data.aws_iam_policy_document.cloudwatch_assume_role.json

  inline_policy {
    name   = "api-gateway-${var.environment}-default"
    policy = data.aws_iam_policy_document.cloudwatch.json
  }
}

# Enable the authorizer lambda to be called by the api-gateway
# TODO: This has not been working. Have had to do it in the API Gateway Console
# under Authorization, Edit Authorizer and enable Invoke Permissions
#
resource "aws_lambda_permission" "authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.authorizer.id}"
}

# Enable the Parnter_Profile lambda to be called by the api-gateway
#
resource "aws_lambda_permission" "partner_profile" {
  statement_id  = "AllowAPIGatewayInvokePartnerProfile"
  action        = "lambda:InvokeFunction"
  function_name = var.aws_partner_profile_lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*/*"
}

# Enable the api_handler lambda to be called by the api-gateway
#
resource "aws_lambda_permission" "api_handler" {
  statement_id  = "AllowAPIGatewayInvokeApiHandler"
  action        = "lambda:InvokeFunction"
  function_name = var.aws_api_handler_lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*/*"
}
