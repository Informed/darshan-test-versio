#####################
## Lambda function ##
#####################

data "aws_s3_bucket" "exchange_bucket" {
  bucket = "informed-techno-core-${var.environment}-exchange"
}

data "aws_iam_policy_document" "app_demo_page_ocr_lambda_permissions" {
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
      "${data.aws_s3_bucket.exchange_bucket.arn}/*/*/*/img/*",
      "${data.aws_s3_bucket.exchange_bucket.arn}/*/*/*/ocr/*",
      data.aws_s3_bucket.exchange_bucket.arn,
    ]
  }
  statement {
    sid       = "EventBridgeAccess"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = ["*"]
  }
  statement {
    sid    = "InvokeLambda"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:informed-${var.environment}-autofund-page-classifier"
    ]
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

module "app_demo_page_ocr_lambda_function" {
  # tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/informed/borg.git//aws-lambda"

  # function configuration
  function_name  = "${var.project_name}-${var.environment}-app-demo-page-ocr"
  handler        = var.lambda_handler_name
  runtime        = var.runtime
  architectures  = var.architectures
  tracing_mode   = var.lambda_tracing_mode
  timeout        = var.timeout
  memory_size    = var.memory_size
  create_package = false
  image_uri      = "992538905015.dkr.ecr.us-west-2.amazonaws.com/cicd:app-demo-page-ocr-latest"
  package_type   = "Image"
  # s3_existing_package = {
  #   bucket = "informed-techno-core-${var.environment}-lambda-images"
  #   key    = var.lambda_handler_file
  # }
  # layers = var.layer_arns

  environment_variables = merge(
    {
      "LOG_LEVEL"                     = var.log_level
      "HONEYBADGER_API_KEY"           = var.app_demo_page_ocr_honeybadger_api_key
      "HONEYBADGER_ENVIRONMENT"       = var.environment
      "HONEYBADGER_FORCE_REPORT_DATA" = var.honeybadger_force_report_data
      "Environment"                   = var.environment
      "POWERTOOLS_METRICS_NAMESPACE"  = "AppDemoPageOcr"
      "GOOGLE_CLOUD_API_KEY"          = var.google_cloud_api_key
    },
    var.extra_environment_variables
  )


  # triggers
  create_current_version_allowed_triggers = false # disables function version invokation restriction

  # lambda role
  role_name          = "${var.project_name}-${var.environment}-app-demo-page-ocr"
  role_description   = "used for ${var.project_name}-${var.environment}-app-demo-page-ocr function"
  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.app_demo_page_ocr_lambda_permissions.json
}
