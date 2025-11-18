/*
Project     : CSB-API-Service Infrastructure Configuration
Module      : Azure App-Service
Description : App-Service module configuration for CSB-API-Service
Context     : Module Outputs
*/

output "app_service_hostname" {
  description = "The default hostname of the deployed App Service."
  value       = azurerm_linux_web_app.main.default_hostname
}

output "app_service_identity_principal_id" {
  description = "The Principal ID of the App Service's System-Assigned Managed Identity."
  value       = azurerm_linux_web_app.main.identity[0].principal_id
}

output "app_service_name" {
  description = "The name of the App Service."
  value       = azurerm_linux_web_app.main.name
}
