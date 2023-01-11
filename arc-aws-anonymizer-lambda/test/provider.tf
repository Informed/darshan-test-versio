provider "aws" {
  region  = "us-west-2"
  profile = "dev"
}

provider "aws" {
  alias   = "source"
  region  = "us-west-2"
  profile = "dev"
}


provider "aws" {
  alias   = "dest"
  region  = "us-west-2"
  profile = "prod-legacy"
}