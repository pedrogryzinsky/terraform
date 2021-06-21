locals {
  container_port = 8000
}

resource "aws_ecr_repository" "socialab" {
  name                 = "${var.stage}-socialab"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_cloudwatch_log_group" "socialab" {
  name              = "${var.stage}-socialab"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "socialab" {
  family       = "socialab"
  network_mode = "bridge"

  container_definitions = jsonencode(
    [
      {
        "name" : "socialab",
        "image" : aws_ecr_repository.socialab.repository_url,
        "cpu" : 0,
        "memory" : 480,
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
            "awslogs-group" : "socialab",
            "awslogs-stream-prefix" : "complete-ecs"
          }
        }
      }
    ]
  )
}

resource "aws_ecs_service" "socialab" {
  name            = "socialab"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.socialab.arn

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
