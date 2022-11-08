terraform {
  required_version = ">= 1.0"

  required_providers {
    source = {
        source  = "hashicorp/aws"
        version = ">= 4.0"
    }
    dest = {
        source  = "hashicorp/aws"
        version = ">= 4.0"
    }
  }
}