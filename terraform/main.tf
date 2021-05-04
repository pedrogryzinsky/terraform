# Random prefix
resource "random_id" "random_id_prefix" {
  byte_length = 2
}

# Variables used in all modules
locals {
  region             = var.region
  availability_zones = ["${var.region}c", "${var.region}f"]
  ec2_resources_name = "${var.stage}-ec2"
}

# Import Modules
module "security" {
  source     = "./modules/security"
  public_key = var.public_key
}

# Create the default VPC
module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = var.stage

  cidr            = "10.1.0.0/16"
  azs             = local.availability_zones
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_ipv6 = true

  tags = {
    Name = var.stage
  }
}

module "ecs" {
  source             = "terraform-aws-modules/ecs/aws"
  name               = "my-ecs"
  container_insights = true
  capacity_providers = [aws_ecs_capacity_provider.default.name]
  default_capacity_provider_strategy = [{
    capacity_provider = aws_ecs_capacity_provider.default.name
    weight            = "1"
  }]
}

resource "aws_ecs_capacity_provider" "default" {
  name = "default"

  auto_scaling_group_provider {
    auto_scaling_group_arn = module.asg.autoscaling_group_arn

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 90
    }
  }
}

module "ec2_profile" {
  source      = "terraform-aws-modules/ecs/aws//modules/ecs-instance-profile"
  name        = var.stage
  include_ssm = true
  tags        = {}
}

#For now we only use the AWS ECS optimized ami <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html>
data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  name = local.ec2_resources_name

  # Launch configuration
  lt_name                = local.ec2_resources_name
  use_lt                 = true
  create_lt              = true
  update_default_version = true

  image_id                 = data.aws_ami.amazon_linux_ecs.id
  instance_type            = "t3.micro"
  security_groups          = [module.network.default_security_group_id]
  iam_instance_profile_arn = module.ec2_profile.iam_instance_profile_arn
  user_data_base64         = base64encode(data.template_file.user_data.rendered)
  key_name                 = module.security.key_name
  ebs_optimized            = true
  enable_monitoring        = true

  # Auto scaling group
  vpc_zone_identifier       = module.network.private_subnets
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 2
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  capacity_rebalance        = true

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 20
        volume_type           = "gp2"
      }
    }
  ]

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  capacity_reservation_specification = {
    capacity_reservation_preference = "open"
  }

  cpu_options = {
    core_count       = 1
    threads_per_core = 1
  }

  credit_specification = {
    cpu_credits = "standard"
  }

  instance_market_options = {
    market_type = "spot"
  }

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 32
  }

  tags = [
    {
      key                 = "socialab:application:stage"
      value               = var.stage
      propagate_at_launch = true
    },
    {
      key                 = "socialab:application:cluster"
      value               = module.ecs.ecs_cluster_name
      propagate_at_launch = true
    },
  ]
}

data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.sh")

  vars = {
    cluster_name = module.ecs.ecs_cluster_name
  }
}

module "hello_world" {
  source            = "./services/demo"
  subnets           = module.network.private_subnets
  sgs               = [module.network.default_security_group_id]
  cluster_id        = module.ecs.ecs_cluster_id
  target_group_arns = module.routing.target_group_arns
}

module "routing" {
  source                    = "./modules/routing"
  subnets                   = module.network.public_subnets
  vpc_id                    = module.network.vpc_id
  stage                     = var.stage
  default_security_group_id = module.network.default_security_group_id
}
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 3.0"

  identifier = "${var.stage}"

  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  name     = "${var.stage}"
  username = "socialab"
  password = random_password.password.result
  port     = "3306"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [module.network.default_security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  tags = {}

  # DB subnet group
  subnet_ids = module.network.private_subnets

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name = "character_set_client"
      value = "utf8mb4"
    },
    {
      name = "character_set_server"
      value = "utf8mb4"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}
