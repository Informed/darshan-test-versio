bucket_prefix                          = "informed"
project_name                           = "techno-core"
dns_base_domain                        = "informediq-infra.com"
eventbridge_create_api_destinations    = true
disable_layers                         = false
environment                            = "staging"
informed_analyze_docs_backend_base_url = "https://api-staging-internal.driveinformed.com"
informed_partner_event_hook            = "https://api-staging-internal.driveinformed.com/api/event_hook/partner"
region                                 = "us-west-2"
profile                                = "staging"
vpc_cidr                               = "30"
single_nat_gateway                     = false
additional_exchange_bucket_privileged_principal_arns = [
  { "arn:aws:iam::120244891341:user/informed-api-user" = [""] },
  { "arn:aws:iam::120244891341:role/lambda-bank-statement-page-classifier-execution-role-us-west-2" = [""] },
  { "arn:aws:iam::120244891341:role/lambda-execution-role-us-west-2" = [""] },
  { "arn:aws:iam::120244891341:role/lambda-vin-corrector-execution-role-us-west-2" = [""] },
  { "arn:aws:iam::120244891341:role/image-processing-elastic-beanstalk-role-us-west-2" = [""] },
  { "arn:aws:iam::120244891341:role/extractions-elastic-beanstalk-role-us-west-2" = [""] }
]
additional_upload_bucket_privileged_principal_arns = [
  { "arn:aws:iam::120244891341:user/informed-api-user" = [""] }
]
additional_download_bucket_privileged_principal_arns = [
  { "arn:aws:iam::120244891341:user/informed-api-user" = [""] },
  { "arn:aws:iam::120244891341:role/informed-staging-us-west-2-lambdaRole" = [""] }
]
