# Declare root outputs in here
output "db_password" {
  value = module.database.db_password
  sensitive = true
}

output "repository_url" {
  value = module.service.repository_url
}
