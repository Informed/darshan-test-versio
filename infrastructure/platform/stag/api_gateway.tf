# TODO: refactor this into separate files for authorizer and api-gateway
# TODO: Delegate the routes to the application modules and not this module
#
locals {
  api_gateway_domain_name                = "api.${var.environment}.${var.dns_base_domain}"
  domain_name                            = "${var.environment}.${var.dns_base_domain}"
  alternative_names                      = []
  stage_name                             = "$default"
  api_gateway_name                       = "${var.project_name}-${var.environment}"
  analyze_docs_versions                  = ["v5", "v6", "v7", "v8"]
  informed_analyze_docs_backend_base_url = var.informed_analyze_docs_backend_base_url
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name = "/aws/api-gateway/${local.api_gateway_name}"

  retention_in_days = 30
}

resource "aws_apigatewayv2_api" "api_gateway" {
  name          = local.api_gateway_name
  description   = "API Gateway for ${var.project_name} ${var.environment} services"
  protocol_type = "HTTP"
}

resource "aws_ssm_parameter" "api_gateway_api_id" {
  name  = "/tc/platform/api_gateway/api_gateway_api_id"
  type  = "String"
  value = aws_apigatewayv2_api.api_gateway.id
}

resource "aws_apigatewayv2_stage" "stage_resource" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = local.stage_name
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
  domain_name                       = local.api_gateway_domain_name
  subject_alternative_names         = local.alternative_names
  process_domain_validation_options = true
  ttl                               = "300"
  wait_for_certificate_issued       = true
  zone_name                         = local.domain_name
}

resource "aws_apigatewayv2_domain_name" "domain_resource" {
  domain_name = local.api_gateway_domain_name
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
##
resource "aws_apigatewayv2_authorizer" "authorizer" {
  api_id                            = aws_apigatewayv2_api.api_gateway.id
  authorizer_type                   = "REQUEST"
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "${var.project_name}-${var.environment}-partner-authorizer"
  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 0
  enable_simple_responses           = false
  authorizer_uri                    = aws_lambda_function.lambda_authorizer.invoke_arn
}

resource "aws_ssm_parameter" "api_gateway_authorizer_id" {
  name  = "/tc/platform/api_gateway/authorizer_id"
  type  = "String"
  value = aws_apigatewayv2_authorizer.authorizer.id
}

data "aws_route53_zone" "api_zone_resource" {
  name = local.domain_name
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
