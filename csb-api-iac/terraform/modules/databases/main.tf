/*
Project     : CSB-API-Service
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

# Create the Redis container group
resource "azurerm_container_group" "redis" {
  name                = "${var.resource_prefix}-redis-server-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [var.redis_subnet_id] # Place redis container in the private subnet

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
      "REDIS_ARGS" = "--requirepass ${random_password.redis_admin.result}"
    }
  }

  tags = var.tags
}
