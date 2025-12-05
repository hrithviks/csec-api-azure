/*
Project     : CSB-API-Service Infrastructure Configuration
Module      : Terraform Root Configuration
Description : Root configuration for CSB-API-Service
Context     : Module Outputs
*/

output "app_service_subnet_id" {
  description = "The ID of the App Service subnet."
  value       = module.network.subnet_ids["csec-app-service-subnet"]
}

output "private_endpoints_subnet_id" {
  description = "The ID of the Private Endpoints subnet."
  value       = module.network.subnet_ids["csec-private-service-subnet"]
}

output "postgres_private_dns_zone_id" {
  description = "The ID of the Private DNS Zone for PostgreSQL."
  value       = module.network.private_dns_zone_ids["postgres"]
}

# Backend Configuration
output "postgres_db_host" {
  description = "The FQDN of the PostgreSQL host server."
  value       = module.databases.postgres_server_fqdn
}

output "postgres_db_name" {
  description = "The name of the PostgreSQL database."
  value       = module.databases.postgres_db_name
}

output "postgres_db_port" {
  description = "The port of the PostgreSQL database server."
  value       = var.csec_api_postgres_port
}

output "postgres_db_admin" {
  description = "The username for the PostgreSQL admin user."
  value       = module.databases.postgres_admin_username
}

output "postgres_db_admin_password" {
  description = "The password for the PostgreSQL admin user."
  value       = module.databases.postgres_admin_password
  sensitive   = true
}

# Set passwords for all database users
output "postgres_db_csb_app_user_password" {
  description = "The password for main application role, owning the schema."
  value       = random_password.csb_app_user_pswd.result
  sensitive   = true
}

output "postgres_db_csb_api_user_password" {
  description = "The password for main application role, owning the schema."
  value       = random_password.csb_api_user_pswd.result
  sensitive   = true
}

output "postgres_db_csb_aws_user_password" {
  description = "The password for main application role, owning the schema."
  value       = random_password.csb_aws_user_pswd.result
  sensitive   = true
}

output "postgres_db_csb_azure_user_password" {
  description = "The password for main application role, owning the schema."
  value       = random_password.csb_azure_user_pswd.result
  sensitive   = true
}
