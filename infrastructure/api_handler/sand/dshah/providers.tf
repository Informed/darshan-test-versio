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
    bucket         = "informed.terraform.us-west-2.sand"
    key            = "dshah/techno-core/api-handler/terraform.tfstate"
    role_arn       = "arn:aws:iam::992538905015:role/iq-cicd-deployer-uswest2-role"
    region         = "us-west-2"
    dynamodb_table = "platform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.region
  assume_role {
    role_arn = "arn:aws:iam::072767837607:role/iq-cicd-deployer-uswest2-role"
  }
  default_tags {
    tags = {
      application = "api-handler"
      environment = var.environment
      repo        = "techno-core"
    }
  }
}
