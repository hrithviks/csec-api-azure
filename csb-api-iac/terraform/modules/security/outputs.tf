/*
Project     : CSB-API-Service
Module      : Azure Security
Description : Security module configuration for CSB-API-Service
Context     : Module Outputs
*/

output "postgres_private_endpoint_ip" {
  description = "The private IP address of the PostgreSQL private endpoint."
  value       = azurerm_private_endpoint.postgres.private_service_connection[0].private_ip_address
}
