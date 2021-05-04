module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "alb-${var.stage}"
  description = "Security group for example usage with ALB"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
}

# module "log_bucket" {
#   source  = "terraform-aws-modules/s3-bucket/aws"
#   version = "~> 1.0"
#
#   bucket                         = "logs"
#   acl                            = "log-delivery-write"
#   force_destroy                  = true
#   attach_elb_log_delivery_policy = true
# }

# module "acm" {
#   source  = "terraform-aws-modules/acm/aws"
#   version = "~> 3.0"

#   domain_name = local.domain_name # trimsuffix(data.aws_route53_zone.this.name, ".") # Terraform >= 0.12.17
#   zone_id     = data.aws_route53_zone.this.id
# }

##################################################################
# Application Load Balancer
##################################################################
module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name = "complete-alb"

  load_balancer_type = "application"

  vpc_id          = var.vpc_id
  security_groups = [var.default_security_group_id, module.security_group.security_group_id]
  subnets         = var.subnets

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      # action_type        = "forward"
    },
  ]

  target_groups = [
    {
      name_prefix          = "h1"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "ip"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
      protocol_version = "HTTP1"
      targets = {
      }
      tags = {
        InstanceTargetGroupTag = "baz"
      }
    },
  ]

  tags = {
    Project = "Unknown"
  }

  lb_tags = {
    MyLoadBalancer = "foo"
  }

  target_group_tags = {
    MyGlobalTargetGroupTag = "bar"
  }

  https_listener_rules_tags = {
    MyLoadBalancerHTTPSListenerRule = "bar"
  }

  https_listeners_tags = {
    MyLoadBalancerHTTPSListener = "bar"
  }

  http_tcp_listeners_tags = {
    MyLoadBalancerTCPListener = "bar"
  }
}
