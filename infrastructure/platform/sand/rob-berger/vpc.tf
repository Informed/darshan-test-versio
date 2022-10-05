data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["dynamodb:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"

      values = [module.vpc.vpc_id]
    }
  }
}

data "aws_iam_policy_document" "endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpc"

      values = [module.vpc.vpc_id]
    }
  }
}

locals {
  vpc_cidr         = "10.${var.vpc_cidr}.0.0/16"
  public_cidr      = "10.${var.vpc_cidr}.0.0/20"
  private_cidr     = "10.${var.vpc_cidr}.20.0/20"
  database_cidr    = "10.${var.vpc_cidr}.40.0/20"
  elasticache_cidr = "10.${var.vpc_cidr}.60.0/20"
  redshift_cidr    = "10.${var.vpc_cidr}.80.0/20"
}

module "vpc" {
  #tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/informed/borg.git//aws-vpc"

  name = var.project_name
  cidr = local.vpc_cidr

  azs                 = ["${data.aws_region.current.name}a", "${data.aws_region.current.name}b", "${data.aws_region.current.name}c"]
  public_subnets      = cidrsubnets(local.public_cidr, 2, 2, 2)
  private_subnets     = cidrsubnets(local.private_cidr, 2, 2, 2)
  database_subnets    = cidrsubnets(local.database_cidr, 2, 2, 2)
  elasticache_subnets = cidrsubnets(local.elasticache_cidr, 2, 2, 2)
  redshift_subnets    = cidrsubnets(local.redshift_cidr, 2, 2, 2)

  single_nat_gateway = var.single_nat_gateway
  enable_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    Name = "${var.project_name}-public"
  }
  private_subnet_tags = {
    Name = "${var.project_name}-private"
  }
  database_subnet_tags = {
    Name = "${var.project_name}-database"
  }
  elasticache_subnet_tags = {
    Name = "${var.project_name}-elasticache"
  }
  redshift_subnet_tags = {
    Name = "${var.project_name}-redshift"
  }
  tags = {
    "Name" = var.project_name
  }
}

###################
## vpc endpoints ##
###################

resource "aws_security_group" "vpc_tls" {
  name_prefix = "${var.project_name}-vpc_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

module "vpc_endpoints" {
  #tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/informed/borg.git//aws-vpc/modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpc_tls.id]

  endpoints = {
    s3 = {
      service = "s3"
      tags    = { Name = "s3-vpc-endpoint" }
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      policy          = data.aws_iam_policy_document.dynamodb_endpoint_policy.json
      tags            = { Name = "dynamodb-vpc-endpoint" }
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_tls.id]
    },
    lambda = {
      service             = "lambda"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ecs = {
      service             = "ecs"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ecs_telemetry = {
      create              = false
      service             = "ecs-telemetry"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_tls.id]
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      policy              = data.aws_iam_policy_document.endpoint_policy.json
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      policy              = data.aws_iam_policy_document.endpoint_policy.json
    },
    kms = {
      service             = "kms"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_tls.id]
    },
  }
}
