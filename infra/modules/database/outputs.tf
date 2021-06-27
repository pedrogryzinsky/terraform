output "db_password" {
  value       = random_password.password.result
  sensitive   = true
  description = "Master user password"
}
