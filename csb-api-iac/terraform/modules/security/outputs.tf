/*
Project     : CSB-API-Service
Module      : Azure Security
Description : Security module configuration for CSB-API-Service
Context     : Module Outputs
*/

output "postgres_private_endpoint_id" {
  description = "The ID of the Postgres Private Endpoint."
  value       = azurerm_private_endpoint.postgres.id
}
