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
    key            = "rob-berger/app-demo-page-ocr/terraform.tfstate"
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
      application = "app-demo-page-ocr"
      environment = var.environment
      repo        = "techno-core"
    }
  }
}
