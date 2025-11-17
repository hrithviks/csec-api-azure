/*
Project     : CSB-API-Service
Module      : Azure Network
Description : Network module configuration for CSB-API-Service
Context     : Module Outputs
*/

output "vnet_id" {
  description = "The ID of the virtual network."
  value       = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  description = "A map of subnet logical names to their resource IDs."
  value       = { for k, v in azurerm_subnet.main : k => v.id }
}

output "private_dns_zone_ids" {
  description = "A map of logical DNS zone names to their resource IDs."
  value       = { for k, v in azurerm_private_dns_zone.main : k => v.id }
}
