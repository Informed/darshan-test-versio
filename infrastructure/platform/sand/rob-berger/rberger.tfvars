bucket_prefix                          = "informed"
project_name                           = "techno-core"
dns_base_domain                        = "informediq-infra.com"
environment                            = "rberger"
informed_analyze_docs_backend_base_url = "https://adp-dev.informediq-infra.com"
eventbridge_create_api_destinations    = true
disable_layers                         = false

# TODO: These need to be adjusted to the environment when the legacy setup is installed in this environment
#
additional_exchange_bucket_privileged_principal_arns = [
  { "arn:aws:iam::450112884190:user/informed-api-user" = [""] },
  { "arn:aws:iam::450112884190:role/lambda-bank-statement-page-classifier-execution-role-us-west-2" = [""] },
  { "arn:aws:iam::450112884190:role/lambda-execution-role-us-west-2" = [""] },
  { "arn:aws:iam::450112884190:role/lambda-vin-corrector-execution-role-us-west-2" = [""] },
  { "arn:aws:iam::450112884190:role/image-processing-elastic-beanstalk-role-us-west-2" = [""] },
  { "arn:aws:iam::450112884190:role/extractions-elastic-beanstalk-role-us-west-2" = [""] }
]
additional_upload_bucket_privileged_principal_arns = [
  { "arn:aws:iam::450112884190:user/informed-api-user" = [""] }
]
additional_download_bucket_privileged_principal_arns = [
  { "arn:aws:iam::450112884190:user/informed-api-user" = [""] },
  { "arn:aws:iam::450112884190:role/informed-dev-us-west-2-lambdaRole" = [""] }
]

# Setup layers for otel and slsdebugger
authorizer_layer_arns = [
  "arn:aws:lambda:us-west-2:901920570463:layer:aws-otel-python-amd64-ver-1-11-1:2",
  # "arn:aws:lambda:us-west-2:545538059309:layer:slsdebugger-python:2",
]

authorizer_handler = "partner_authorizer.handler"
# authorizer_handler = "slsdebugger.handler.wrapper"
# authorizer_extra_environment_variables = {
#   "SLSDEBUGGER_AUTH_TOKEN"     = "YoPj5Ha1GB3s5jrAyqFqnUjk1WO2OlVCDsUCdrDhxKY="
#   "SLSDEBUGGER_LAMBDA_HANDLER" = "partner_authorizer.handler"
# }

# Config somewhat customized for the rberger environment
authorizer_runtime       = "python3.8"
authorizer_architectures = ["x86_64"]
region                   = "us-west-2"
profile                  = "rberger"
vpc_cidr                 = "10"
single_nat_gateway       = true
