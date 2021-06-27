resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 3.0"

  identifier = "${var.stage}-socialab-db"

  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  name     = var.stage
  username = "socialab"
  password = random_password.password.result
  port     = "3306"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = var.security_groups

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  tags = {}

  # DB subnet group
  subnet_ids = var.instance_subnets

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
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

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.stage}/socialab/DB_PASSWORD"
  description = "The Database Master Password"
  type        = "SecureString"
  value       = random_password.password.result
}

# TODO: Fix here, db_instance_endpoint contains also the port
resource "aws_ssm_parameter" "db_host" {
  name        = "/${var.stage}/socialab/DB_HOST"
  description = "The Database Master Password"
  type        = "String"
  value       = module.db.db_instance_endpoint
}


resource "aws_ssm_parameter" "db_port" {
  name        = "/${var.stage}/socialab/DB_PORT"
  description = "The Database Port"
  type        = "String"
  value       = module.db.db_instance_port
}


resource "aws_ssm_parameter" "db_user" {
  name        = "/${var.stage}/socialab/DB_USER"
  description = "The Database User"
  type        = "String"
  value       =  module.db.db_instance_username
}




