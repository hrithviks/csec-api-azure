/*
Project     : CSB-API-Service
Module      : Azure Network
Description : Network module configuration for CSB-API-Service
Context     : Module Outputs
*/

output "private_subnet_id" {
  description = "The ID of the private subnet."
  value       = azurerm_subnet.main["${var.resource_prefix}-private-service-subnet"].id
}

output "app_service_subnet_id" {
  description = "The ID of the app service subnet."
  value       = azurerm_subnet.main["${var.resource_prefix}-app-service-subnet"].id
}