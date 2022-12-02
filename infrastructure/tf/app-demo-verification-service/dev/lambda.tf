data "aws_s3_bucket" "exchange_bucket" {
  bucket = "informed-techno-core-${var.environment}-exchange"
}

#####################
## Lambda function ##
#####################

data "aws_iam_policy_document" "app_demo_verification_service_lambda_permissions" {
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
      "${data.aws_s3_bucket.exchange_bucket.arn}/*/*/application/*",
      "${data.aws_s3_bucket.exchange_bucket.arn}/*/*/stip_verifications/*",
      "${data.aws_s3_bucket.exchange_bucket.arn}/*/*/documents/*",
      data.aws_s3_bucket.exchange_bucket.arn
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
  statement {
    sid     = "DynamodbAccess"
    effect  = "Allow"
    actions = ["dynamodb:*"]
    resources = [
      "*"
    ]
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
}

module "app_demo_verification_service_lambda_function" {
  # tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/informed/borg.git//aws-lambda"

  # function configuration
  function_name  = "${var.project_name}-${var.environment}-app-demo-verification-service"
  handler        = var.lambda_handler_name
  runtime        = var.runtime
  architectures  = var.architectures
  tracing_mode   = var.lambda_tracing_mode
  timeout        = var.timeout
  memory_size    = var.memory_size
  create_package = false
  package_type   = "Image"
  image_uri      = "992538905015.dkr.ecr.us-west-2.amazonaws.com/cicd:app-demo-verification-service-${var.environment}-latest"
  layers         = var.layer_arns

  environment_variables = merge(
    {
      "LOG_LEVEL"                     = var.log_level
      "HONEYBADGER_API_KEY"           = var.app_demo_verification_service_honeybadger_api_key
      "HONEYBADGER_ENVIRONMENT"       = var.environment
      "HONEYBADGER_FORCE_REPORT_DATA" = var.honeybadger_force_report_data
      "Environment"                   = var.environment
      "EMPLOYER_NAME_LOOKUP_ENABLED"  = true
      "AWS_DEFAULT_BUCKET"            = data.aws_s3_bucket.exchange_bucket.id
      "GEOCODE_TOKEN"                 = "Wu3e2Jz9Lr8YjMg9C2cjqBZTcKP18v9TpEsV2EyckWpX3xCx7Kai5uatnZZGpx2v"
    },
    var.extra_environment_variables
  )


  # triggers
  create_current_version_allowed_triggers = false # disables function version invokation restriction

  # lambda role
  role_name          = "${var.project_name}-${var.environment}-app-demo-verification-service-${data.aws_region.current.name}"
  role_description   = "used for ${var.project_name}-${var.environment}-app-demo-verification-service function"
  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.app_demo_verification_service_lambda_permissions.json
}
