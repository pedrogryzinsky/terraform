/////////// LOCALS /////////////
locals {
  ec2_resources_name = "${var.stage}-ec2"
}

/////////// DATA //////////////
data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.sh")

  vars = {
    cluster_name = module.ecs.ecs_cluster_name
  }
}

# For now we only use the AWS ECS optimized ami <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html>
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

/////////// MODULES //////////////
module "ec2_profile" {
  source      = "terraform-aws-modules/ecs/aws//modules/ecs-instance-profile"
  name        = var.stage
  include_ssm = true
}

module "ecs" {
  source             = "terraform-aws-modules/ecs/aws"
  name               = "${var.stage}-socialab-cluster"
  container_insights = true
  capacity_providers = [aws_ecs_capacity_provider.default.name]

  default_capacity_provider_strategy = [{
    capacity_provider = aws_ecs_capacity_provider.default.name
    weight            = "1"
  }]
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
  security_groups          = var.security_groups
  iam_instance_profile_arn = module.ec2_profile.iam_instance_profile_arn
  user_data_base64         = base64encode(data.template_file.user_data.rendered)
  key_name                 = var.key_name
  ebs_optimized            = true
  enable_monitoring        = true

  # Auto scaling group
  vpc_zone_identifier       = var.instance_subnets
  health_check_type         = "EC2"
  min_size                  = 1
  max_size                  = 1
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

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 32
  }
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
