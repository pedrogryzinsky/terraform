locals {
  container_port = 8000
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_ecr_repository" "socialab" {
  name                 = "${var.stage}-socialab"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/${var.stage}/socialab/DB_NAME"
  description = "The Application Database Name"
  type        = "String"
  value       =  "${var.stage}-socialab"
}

resource "aws_cloudwatch_log_group" "socialab" {
  name              = "${var.stage}-socialab"
  retention_in_days = 1
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ssm_policy" {
  name        = "ssm_policy"
  path        = "/"
  description = "Allow ECS agent to fetch SSM secrets"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:*",
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_ssm_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = aws_iam_policy.ssm_policy.arn
}

# TODO: Fix here
resource "aws_ecs_task_definition" "socialab" {
  family       = "${var.stage}-socialab"
  network_mode = "bridge"
  # execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"

  container_definitions = jsonencode(
    [
      {
        "name" : "socialab",
        "image" : aws_ecr_repository.socialab.repository_url,
        "cpu" : 256,
        "memory" : 512,
        "portMappings" : [
          {
            "containerPort" : local.container_port,
            "hostPort" : 0
          }
        ],
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-region" : "us-east-1",
            "awslogs-group" : aws_cloudwatch_log_group.socialab.name,
            "awslogs-stream-prefix" : "complete-ecs"
          }
        }
#         "secrets": [
#          { "name": "DB_NAME", "valueFrom": "/${var.stage}/socialab/DB_NAME"},
#          { "name": "DB_USER", "valueFrom": "/${var.stage}/socialab/DB_USER"},
#          { "name": "DB_PASSWORD", "valueFrom": "/${var.stage}/socialab/DB_PASSWORD"},
#          { "name": "DB_HOST", "valueFrom": "/${var.stage}/socialab/DB_HOST"},
#          { "name": "DB_PORT", "valueFrom": "/${var.stage}/socialab/DB_PORT"},
#        ]
      }
    ]
  )
}

resource "aws_ecs_service" "socialab" {
  name            = "socialab"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.socialab.arn
  health_check_grace_period_seconds = 60

  load_balancer {
    target_group_arn = var.target_group_arns[0]
    container_name   = "socialab"
    container_port   = local.container_port
  }

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  lifecycle {
    ignore_changes = [desired_count]
  }
}
