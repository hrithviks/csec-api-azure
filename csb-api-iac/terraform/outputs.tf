/*
Project     : CSB-API-Service
Module      : Terraform Root Configuration
Description : Root configuration for CSB-API-Service
Context     : Module Outputs
*/

output "app_service_subnet_id" {
  description = "The ID of the App Service subnet."
  value       = module.network.app_service_subnet_id
}

output "private_endpoints_subnet_id" {
  description = "The ID of the Private Endpoints subnet."
  value       = module.network.private_endpoints_subnet_id
}

output "postgres_private_dns_zone_id" {
  description = "The ID of the Private DNS Zone for PostgreSQL."
  value       = module.network.postgres_private_dns_zone_id
}
