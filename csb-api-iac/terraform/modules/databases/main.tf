/*
Project     : CSB-API-Service Infrastructure Configuration
Module      : Azure Databases
Description : Databases module configuration for CSB-API-Service
Context     : Module Main
*/

########################
# PostgreSQL Resources #
########################

# Create a random password for the administrator user
resource "random_password" "postgres_admin" {
  length  = var.postgres_admin_password_chars
  special = true
}

# Create the PostgreSQL flexible server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.resource_prefix}-psql-server-${var.environment}"
  location               = var.location
  resource_group_name    = var.resource_group_name
  version                = var.postgres_db_version
  sku_name               = var.postgres_sku
  storage_mb             = var.postgres_storage_size
  administrator_login    = var.postgres_admin_user
  administrator_password = random_password.postgres_admin.result

  # Disabale public access
  public_network_access_enabled = false

  backup_retention_days        = var.postgres_backup_retention_days
  geo_redundant_backup_enabled = false

  tags = var.tags

  lifecycle {
    ignore_changes = [
      zone,
    ]
  }
}

# Create the PostgreSQL database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "${var.resource_prefix}-psql-db-${var.environment}"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = var.postgres_charset
  collation = var.postgres_collation
}

########################
# Redis Cache Database #
########################

# Create a random password for the redis container
resource "random_password" "redis_admin" {
  length  = var.redis_admin_password_chars
  special = true
}

# Create a random password for the csb-api redis user
resource "random_password" "redis_csb_api_user" {
  length  = var.redis_admin_password_chars
  special = true
}

/* Note: The Redis deployment using Azure Container Instances is intended for
demonstration purposes and has limitations for enterprise-grade production use.
Key Architectural Considerations for a production environment include:

- Data Persistence: The current ACI deployment has ephemeral storage, meaning
  data will be lost if the container restarts. For production, consider
  mounting an Azure File Share to the container group for persistent storage.
  Alternatively, using a managed service like Azure Cache for Redis would
  provide built-in persistence and high availability.

- Secure Authentication: While secure environment variables are used, a more
  robust, enterprise-grade approach would involve storing secrets in Azure Key
  Vault. The container application could then authenticate using a Managed
  Identity to retrieve credentials from the vault at runtime, eliminating the
  need to pass passwords as environment variables.
*/

# Create the Redis container group
resource "azurerm_container_group" "redis" {
  name                = "${var.resource_prefix}-redis-server-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [var.redis_subnet_id] # Place redis container in the private subnet

  # Add credentials for pulling images from a private registry like ghcr.io
  image_registry_credential {
    server   = "ghcr.io"
    username = var.redis_image_registry_user
    password = var.redis_image_registry_password
  }

  container {
    name   = "${var.resource_prefix}-redis-container-${var.environment}"
    image  = var.redis_image
    cpu    = var.redis_cpu
    memory = var.redis_memory

    ports {
      port     = 6379
      protocol = "TCP"
    }

    secure_environment_variables = {
      # Environment variables for entrypoint script
      "REDIS_ADMIN_PASSWORD"   = random_password.redis_admin.result,
      "REDIS_CSB_API_USER"     = var.redis_csb_api_user,
      "REDIS_CSB_API_PASSWORD" = random_password.redis_csb_api_user.result
    }
  }

  tags = var.tags
}
