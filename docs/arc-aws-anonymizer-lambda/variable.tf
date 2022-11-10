variable "environment" {
  description = "Name of this environment"
  type        = string
}

variable "profile" {
  description = "Region to deploy terraform resources to"
  type        = string
}

variable "region" {
  description = "Region to deploy terraform resources to"
  type        = string
  default     = "us-west-2"
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "src_bucket" {
  description = "backend key"
  type        = string
}

variable "dest_bucket" {
  description = "dynamodb table"
  type        = string
}

###
# Documents PII
###

variable "add_documents_PII" {
  type    = string
  default = "first_name,last_name,middle_name,suffix,email,ssn,driver_license_number,date_of_birth,dob,account_number,bank_account_number,vin,id_number, policy_number,tin,itin,applicant_phone_number,trade_in_vin,zip,city,state,street_2,street_address,phone"
}

variable "remove_documents_PII" {
  type    = string
  default = "analysis_document_payload"
}

###
# Applications PII
###

variable "add_application_PII" {
  type    = string
  default = "first_name,last_name,middle_name,suffix,email,ssn,date_of_birth,dob,account_number,bank_account_number,vin,id_number, policy_number,tin,itin,zip,city,state,street_2,street_address,phone"
}

variable "remove_application_PII" {
  type    = string
  default = ""
}

###
# Stip verification PII
###

variable "add_stip_verification_PII" {
  type    = string
  default = "matches_applicant_name, matches_applicant2_name,matches_applicant1_name,matches_applicant1_ssn, matches_applicant1_address, matches_applicant2_ssn, matches_applicant2_address, matches_applicant1_dob, matches_applicant2_dob,matches_applicant1_vin, matches_applicant2_vin, matches_applicant_address,matches_applicant_ssn,vin,policy_number,matches_applicant_vin, matches_approval_vin,account_number,matches_contract_vin,matches_approval_vin,dob,is_ssi_deposit_referencing_applicant_name,matches_applicant_dob"
    
}

variable "add_stip_verification_list_PII" {
  type    = string
  default = "recommendations"
    
}

variable "remove_stip_verification_PII" {
  type    = string
  default = ""
}