bucket_prefix                          = "informed"
project_name                           = "techno-core"
dns_base_domain                        = "informediq-infra.com"
environment                            = "qa"
informed_analyze_docs_backend_base_url = "https://api-qa-internal.driveinformed.com"
informed_partner_event_hook            = "https://api-qa-internal.driveinformed.com/api/event_hook/partner"
region                                 = "us-west-2"
profile                                = "qa"
vpc_cidr                               = "20"
single_nat_gateway                     = true
eventbridge_create_api_destinations    = true
disable_layers                         = false
additional_exchange_bucket_privileged_principal_arns = [
  { "arn:aws:iam::949710002353:user/informed-api-user" = [""] },
  { "arn:aws:iam::949710002353:role/lambda-bank-statement-page-classifier-execution-role-us-west-2" = [""] },
  { "arn:aws:iam::949710002353:role/lambda-execution-role-us-west-2" = [""] },
  { "arn:aws:iam::949710002353:role/lambda-vin-corrector-execution-role-us-west-2" = [""] },
  { "arn:aws:iam::949710002353:role/image-processing-elastic-beanstalk-role-us-west-2" = [""] },
  { "arn:aws:iam::949710002353:role/extractions-elastic-beanstalk-role-us-west-2" = [""] }
]
additional_upload_bucket_privileged_principal_arns = [
  { "arn:aws:iam::949710002353:user/informed-api-user" = [""] }
]
additional_download_bucket_privileged_principal_arns = [
  { "arn:aws:iam::949710002353:user/informed-api-user" = [""] },
  { "arn:aws:iam::949710002353:role/informed-qa-us-west-2-lambdaRole" = [""] }
]
