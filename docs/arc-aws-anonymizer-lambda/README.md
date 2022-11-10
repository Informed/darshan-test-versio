# terraform-arc-aws-anonymizer-lambda
Terraform Module to set up anonymized lambda function.
----------------------

## What this module does
Set-up Lambda with below capabilty:
- Encrypt(SHA-256 + BASE64) PII data and copy over to destination bucket as soon as it is uploaded to source bucket.
- Delete PII data from destination bucket as soon as it is deleted from source bucket. 

Here is the document consists of PII keys which are encrypted to destination bucket. 

--- https://docs.google.com/document/d/1PscLShKBS2c5WbvL2XRNYbuW7LU-cG9JM_1r3ImfEfU/edit?usp=sharing ---

## Required

- AWS provider >= 4.8
- Terraform 1.1.7 module provider inheritance block:
- You need to have versioning enabled for Source Bucket.

- `aws.source` - AWS provider alias for source account
- `aws.dest`   - AWS provider alias for destination account

### Variables

You can see description of each variable on `variables.tf` file. The ones that does not have a default value, are required.

```hcl

module "anonymized_lambda" {
  source             = "git::https://github.com/informed/borg.git//arc-aws-anonymizer-lambda"

  app_name           = var.app_name
  source_bucket      = var.source_bucket
  destination_bucket = var.destination_bucket
  environment        = var.environment

  providers = {
    aws.source = aws.source
    aws.dest   = aws.dest
  }
}

provider "aws" {
  alias  = "source"
  region = "us-west-2"
  profile = "your-profile"
}


provider "aws" {
  alias  = "dest"
  region = "us-east-2"
  profile = "your-profile"
}

```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Instruction set environement for your Lambda function. Valid values are ["dev"], ["dev-api"],["qa"] ["staging"], ["prod"]. | `string` | `null` | yes |
| <a name="input_profile"></a> [profile](#input\_profile) | AWS Profile to use for | `string` | `null` | yes |
| <a name="input_region"></a> [assume\_region](#input\_region) | AWS Region to deploy to | `string` | `null` | yes |
| <a name="input_app_name"></a> [attach\_app\_name](#input\_app\_name) | App name should be appended to `anonymized-copy` and `anonymized-delete` function.  | `string` | `null` | yes |
| <a name="input_src_bucket"></a> [attach\_src\_bucket](#input\_src\_bucket) | Bucket name which has PII data which needs to be anonymized | `string` | `null` | yes |
| <a name="input_dest_bucket"></a> [attach\_dest\_bucket](#input\_dest\_bucket) | Bucket name which needs to have anonymized PII data  | `string` | `null` | yes |
| <a name="input_add_documents_PII"></a> [add\_documents\_PII](#input\_add\_documents\_PII) | Keys of Documents type documents which needs to be anonymized | `string` | `first_name,last_name,middle_name,suffix,email,ssn,driver_license_number,date_of_birth,dob,account_number,bank_account_number,vin,id_number, policy_number,tin,itin,applicant_phone_number,trade_in_vin,zip,city,state,street_2,street_address,phone` | no |
| <a name="input_remove_documents_PII"></a> [add\_remove\_documents\_PII](#input\_remove\_documents\_PII) | Keys of Documents type documents which needs to be removed before copying over to destination bucket | `string` | `analysis_document_payload` | no |
| <a name="input_add_application_PII"></a> [add\_add\_application\_PII](#input\_add\_application\_PII) | Keys of application type documents which needs to be anonymized | `string` | `first_name,last_name,middle_name,suffix,email,ssn,date_of_birth,dob,account_number,bank_account_number,vin,id_number, policy_number,tin,itin,zip,city,state,street_2,street_address,phone` | no |
| <a name="input_remove_application_PII"></a> [add\_remove\_application\_PII](#input\_remove\_application\_PII) | Keys of Application type documents which needs to be removed before copying over to destination bucket | `string` | `null` | no |
| <a name="input_add_stip_verification_PII"></a> [add\_add\_stip\_verification\_PII](#input\_add\_stip\_verification\_PII) | Keys of Stip verification type documents which has `expected` and `answers` and that key needs to be anonymized before copying over to destination bucket | `string` | `null` | no |
| <a name="input_add_stip_verification_list_PII"></a> [add\_add\_stip\_verification\_list\_PII](#input\_add\_stip\_verification\_list\_PII) | Keys of Stip verification type documents which needs to be anonymized | `string` | `recommendations` | no |
| <a name="input_remove_stip_verification_PII"></a> [add\_remove\_stip\_verification\_PII](#input\_emove\_stip\_verification\_PII) | Keys of Stip verification type documents which needs to be removed before copying over to destination bucket | `string` | `null` | no |

### Arch Diagram 

https://s.icepanel.io/dDZq4D1WrI/5TDD