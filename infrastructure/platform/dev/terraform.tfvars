bucket_prefix                          = "informed"
project_name                           = "techno-core"
dns_base_domain                        = "informediq-infra.com"
environment                            = "dev"
informed_analyze_docs_backend_base_url = "https://adp-dev.informediq-infra.com"
eventbridge_create_api_destinations    = true
disable_layers                         = false
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
region             = "us-west-2"
profile            = "dev"
vpc_cidr           = "10"
single_nat_gateway = true
