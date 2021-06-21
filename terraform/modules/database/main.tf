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
