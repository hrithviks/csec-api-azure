/*
Project     : CSB-API-Service
Module      : Azure Databases
Description : Databases module configuration for CSB-API-Service
Context     : Module Outputs
*/

##########################
# PostgreSQL Outputs     #
##########################

output "postgres_server_id" {
  description = "The ID of the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server.main.id
}

output "postgres_server_fqdn" {
  description = "The FQDN of the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_db_name" {
  description = "The name of the PostgreSQL database."
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "postgres_admin_password" {
  description = "The administrator password for the PostgreSQL server."
  value       = random_password.postgres_admin.result
  sensitive   = true
}

output "postgres_admin_username" {
  description = "The administrator username for the PostgreSQL server."
  value       = var.postgres_admin_user
}

###################
# Redis Outputs   #
###################

output "redis_ip_address" {
  description = "The IP address of the redis cache."
  value       = azurerm_container_group.redis.ip_address
}

output "redis_fqdn" {
  description = "The FQDN of the redis cache."
  value       = azurerm_container_group.redis.fqdn
}

output "redis_password" {
  description = "The password for redis cache."
  value       = random_password.redis_admin.result
  sensitive   = true
}
