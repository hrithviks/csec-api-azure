/*
Project     : CSB-API-Service
Module      : Azure Network
Description : Network module configuration for CSB-API-Service
Context     : Module Outputs
*/

output "subnet_ids" {
  description = "A map of subnet names to their IDs."
  value = {
    for k, v in azurerm_subnet.main : k => v.id
  }
}

output "private_dns_zone_ids" {
  description = "A map of private DNS zone logical names to their IDs."
  value = {
    for k, v in azurerm_private_dns_zone.main : k => v.id
  }
}
