data "aws_ssm_parameter" "api_gateway_api_id" {
  name = "/tc/platform/api_gateway/api_gateway_api_id"
}

data "aws_apigatewayv2_api" "api_gateway" {
  api_id = data.aws_ssm_parameter.api_gateway_api_id.value
}

data "aws_s3_bucket" "exchange_bucket" {
  bucket = "informed-techno-core-${var.environment}-exchange"
}

data "aws_s3_bucket" "downloads_bucket" {
  bucket = "informed-techno-core-${var.environment}-downloads"
}

#####################
## Lambda function ##
#####################

data "aws_iam_policy_document" "response_handler_lambda_permissions" {
  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAttributes",
      "s3:GetObjectVersion",
      "s3:ListBucketVersions",
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:GetBucketLocation",
    ]
    resources = [
      "${data.aws_s3_bucket.exchange_bucket.arn}/*/*/app_request/*",
      "${data.aws_s3_bucket.exchange_bucket.arn}/*/*/stip_verifications/*",
      "${data.aws_s3_bucket.exchange_bucket.arn}/*/*/webhooks/*",
      "${data.aws_s3_bucket.exchange_bucket.arn}/*/*/documents/*",
      data.aws_s3_bucket.exchange_bucket.arn,
      "${data.aws_s3_bucket.downloads_bucket.arn}/*",
      data.aws_s3_bucket.downloads_bucket.arn
    ]
  }
  statement {
    sid       = "EventBridgeAccess"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = ["*"]
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

module "response_handler_lambda_function" {
  # tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/informed/borg.git//aws-lambda"

  # function configuration
  function_name  = "${var.project_name}-${var.environment}-response-handler"
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
      "HONEYBADGER_API_KEY"                 = var.response_handler_honeybadger_api_key
      "HONEYBADGER_ENVIRONMENT"             = var.environment
      "HONEYBADGER_FORCE_REPORT_DATA"       = var.honeybadger_force_report_data
      "Environment"                         = var.environment
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
  role_name          = "${var.project_name}-${var.environment}-response-handler"
  role_description   = "used for ${var.project_name}-${var.environment}-response-handler function"
  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.response_handler_lambda_permissions.json
}
