# Declare root outputs in here
output "db_password" {
  value = module.database.db_password
  sensitive = true
}
