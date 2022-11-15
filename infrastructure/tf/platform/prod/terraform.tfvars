bucket_prefix                          = "informed"
project_name                           = "techno-core"
dns_base_domain                        = "informediq-infra.com"
environment                            = "prod"
informed_analyze_docs_backend_base_url = "https://adp-prod.driveinformed.com"
informed_partner_event_hook            = "https://api-prod-internal.driveinformed.com/api/event_hook/partner"
region                                 = "us-west-2"
profile                                = "prod"
vpc_cidr                               = "40"
single_nat_gateway                     = false
eventbridge_create_api_destinations    = true
disable_layers                         = false
additional_exchange_bucket_privileged_principal_arns = [
  { "arn:aws:iam::607194293212:user/informed-api-user" = [""] },
  { "arn:aws:iam::607194293212:role/lambda-bank-statement-page-classifier-execution-role-us-west-2" = [""] },
  { "arn:aws:iam::607194293212:role/lambda-execution-role-us-west-2" = [""] },
  { "arn:aws:iam::607194293212:role/lambda-vin-corrector-execution-role-us-west-2" = [""] },
  { "arn:aws:iam::607194293212:role/image-processing-elastic-beanstalk-role-us-west-2" = [""] },
  { "arn:aws:iam::607194293212:role/extractions-elastic-beanstalk-role-us-west-2" = [""] }
]
additional_upload_bucket_privileged_principal_arns = [
  { "arn:aws:iam::607194293212:user/informed-api-user" = [""] }
]
additional_download_bucket_privileged_principal_arns = [
  { "arn:aws:iam::607194293212:user/informed-api-user" = [""] },
  { "arn:aws:iam::607194293212:role/informed-prod-us-west-2-lambdaRole" = [""] }
]
