/*
Project     : CSB-API-Service
Module      : Azure Security
Description : Security module configuration for CSB-API-Service
Context     : Module Main
*/

# Private endpoint for PostgreSQL database service
resource "azurerm_private_endpoint" "postgres" {
  name                = "${var.resource_prefix}-postgres-pvt-end-point-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id

  # Create a "A" record
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_ids["postgres"]]
  }

  # Connects the end point to the actual PostgreSQL DB server
  private_service_connection {
    name                           = "${var.resource_prefix}-postgres-pvt-svc-conn-${var.environment}"
    is_manual_connection           = false
    private_connection_resource_id = var.postgres_server_id
    subresource_names              = ["postgresqlServer"] # This is the sub-resource for Postgres
  }

  tags = var.tags
}
