// This is the main entrypoint for loading all modules.
// The file is divided into variables and module calls.
// Do not create any resources in here.

//////////////////// MODULES /////////////////////
module "network" {
  source  = "./modules/network"
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
  security_groups           = [module.network.default_security_group_id]
  use_existing_route53_zone = var.use_existing_route53_zone
}

module "service" {
  source            = "./services/socialab"
  stage             = var.stage
  subnets           = module.network.private_subnets
  security_groups   = [module.network.default_security_group_id]
  cluster_id        = module.computing.ecs_cluster_id
  target_group_arns = module.routing.target_group_arns
}
