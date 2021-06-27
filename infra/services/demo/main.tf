locals {
  container_port = 80
}

resource "aws_cloudwatch_log_group" "hello_world" {
  name              = "hello_world"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "hello_world" {
  family       = "hello_world"
  network_mode = "bridge"

  container_definitions = jsonencode(
    [
      {
        "name" : "hello_world",
        "image" : "nginxdemos/hello",
        "cpu" : 0,
        "memory" : 128,
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
            "awslogs-group" : "hello_world",
            "awslogs-stream-prefix" : "complete-ecs"
          }
        }
      }
    ]
  )
}

resource "aws_ecs_service" "hello_world" {
  name            = "hello_world"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.hello_world.arn

  load_balancer {
    target_group_arn = var.target_group_arns[0]
    container_name   = "hello_world"
    container_port   = local.container_port
  }

  desired_count = 2

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  lifecycle {
    ignore_changes = [desired_count]
  }
}
