data "aws_region" "current" {}

locals {
  stage                = var.stage
  azs                  = var.availability_zones
  cidr                 = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
}

module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name            = "${local.stage}-network"
  azs             = local.azs
  cidr            = var.vpc_cidr
  public_subnets  = var.public_subnets_cidr
  private_subnets = var.private_subnets_cidr
  enable_ipv6     = true

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}
