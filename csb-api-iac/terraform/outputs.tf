/*
Project     : CSB-API-Service
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
