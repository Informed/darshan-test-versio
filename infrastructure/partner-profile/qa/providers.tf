# TODO: Refactor to support the partner_profile service to legacy and everything to TechnoCore environments
# TODO: Refactor to use `techno` instead of `techo-core` for namespacing

/** Use remote state through terraform cloud */
terraform {
  required_version = ">= 1.1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.6"
    }
  }

  backend "s3" {
    bucket         = "informed.terraform.us-west-2.qa"
    key            = "techno-core/partner-profile/terraform.tfstate"
    profile        = "cicd"
    region         = "us-west-2"
    dynamodb_table = "platform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      application = "partner-profile"
      environment = var.environment
      repo        = "techno-core"
    }
  }
}
