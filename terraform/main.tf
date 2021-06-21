# Random prefix
resource "random_id" "random_id_prefix" {
  byte_length = 2
}

# Variables used in all modules
locals {
  region             = var.region
  availability_zones = var.azs
  ec2_resources_name = "${var.stage}-ec2"
}

# Create the default VPC
module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name            = "${var.stage}-network"
  azs             = local.availability_zones
  cidr            = var.vpc_cidr
  public_subnets  = var.public_subnets_cidr
  private_subnets = var.private_subnets_cidr
  enable_ipv6     = true

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}

# Create keypair for EC2 access
module "security" {
  source     = "./modules/security"
  stage      = var.stage
  public_key = var.public_key
}

module "computing" {
  source           = "./modules/computing"
  stage            = var.stage
  security_groups  = [module.network.default_security_group_id]
  key_name         = module.security.key_name
  instance_subnets = module.network.private_subnets
}

module "database" {
  source           = "./modules/database"
  stage            = var.stage
  security_groups  = [module.network.default_security_group_id]
  instance_subnets = module.network.private_subnets
}

module "routing" {
  source                    = "./modules/routing"
  stage                     = var.stage
  vpc_id                    = module.network.vpc_id
  subnets                   = module.network.public_subnets
  security_groups = [module.network.default_security_group_id]
}

module "service" {
  source            = "./services/socialab"
  stage = var.stage
  subnets           = module.network.private_subnets
  security_groups               = [module.network.default_security_group_id]
  cluster_id        = module.computing.ecs_cluster_id
  target_group_arns = module.routing.target_group_arns
}

# Create general module for Docker
#module "docker" {
#  source = "./modules/docker"
# stage  = var.stage
# }
