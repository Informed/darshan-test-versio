resource "aws_lambda_function" "lambda_authorizer" {
  function_name = "${var.project_name}-${var.environment}-partner-authorizer"

  filename = "../../../dummy_lambdas/partner_authorizer.zip"
  runtime  = var.authorizer_runtime
  handler  = var.authorizer_handler

  memory_size   = var.authorizer_memory_size
  timeout       = var.authorizer_timeout
  architectures = var.authorizer_architectures
  role          = aws_iam_role.lambda_authorizer_exec.arn
  layers        = var.disable_layers ? [] : var.authorizer_layer_arns

  tracing_config {
    mode = var.authorizer_tracing_mode
  }

  environment {
    variables = merge(
      {
        "AWS_LAMBDA_EXEC_WRAPPER"             = "/opt/otel-instrument"
        "LOG_LEVEL"                           = "INFO"
        "OPENTELEMETRY_COLLECTOR_CONFIG_FILE" = "/var/task/app/config/${var.environment}_otel_collector.yaml"
        "HONEYBADGER_API_KEY"                 = var.authorizer_honeybadger_api_key
        "HONEYBADGER_ENVIRONMENT"             = var.environment
        "HONEYBADGER_FORCE_REPORT_DATA"       = var.honeybadger_force_report_data
        "Environment"                         = var.environment
      }, var.authorizer_extra_environment_variables
    )
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
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/tc/${var.environment}/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_role" "lambda_authorizer_exec" {
  name = "${local.api_gateway_name}-authorizer"

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
    effect    = "Allow"
    resources = ["*"]
  }
}

# For some reason using aws_iam_role_policy does not work consistently here
resource "aws_iam_policy" "invoke_function" {
  name = "${local.api_gateway_name}-authorizer_invoke_function"

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
  name = "${local.api_gateway_name}-otel-permissions"

  policy = data.aws_iam_policy_document.authorizer_otel_permissions.json
}

resource "aws_iam_role_policy_attachment" "authorizer-otel-permissions" {
  role       = aws_iam_role.lambda_authorizer_exec.name
  policy_arn = aws_iam_policy.authorizer-otel-permissions.arn
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
