output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.db_instance.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.db_instance.port
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.db_instance.username
}