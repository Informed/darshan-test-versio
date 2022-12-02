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
    bucket         = "informed.terraform.us-west-2.dev"
    key            = "techno-core/app-demo-verification-service/terraform.tfstate"
    role_arn       = "arn:aws:iam::992538905015:role/iq-cicd-deployer-uswest2-role"
    region         = "us-west-2"
    dynamodb_table = "platform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::450112884190:role/iq-cicd-deployer-uswest2-role"
  }
  default_tags {
    tags = {
      application = "app-demo-verification-service"
      environment = var.environment
      repo        = "techno-core"
    }
  }
}
