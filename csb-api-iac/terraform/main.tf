/*
Project     : CSB-API-Service
Module      : Terraform Root Configuration
Description : Root configuration for CSB-API-Service
Context     : Module Main
*/

################################
# Reusable local configuration #
################################

locals {
  csb_resource_tags = {
    environment  = var.app_environment
    contact_info = "csbapiadmin@csecbridge.org"
    app_name     = "CSB-API-Service"
  }
}

###########################################
# Main Resource Group for the application #
###########################################

resource "azurerm_resource_group" "main" {
  name     = "${var.app_resource_group_name}-${var.app_environment}"
  location = var.app_location
  tags     = local.csb_resource_tags
}

############################
# Create Network Resources #
############################

module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.app_location
  resource_prefix     = var.app_resource_name_prefix
  environment         = var.app_environment
  vnet_address_space  = var.vnet_address_cidr
  tags                = local.csb_resource_tags

  # Pass the entire subnet map to the module
  subnets_map = var.vnet_subnets_map

  # Pass the new map of DNS zones
  private_dns_zones = var.vnet_private_dns_zones

  # Pass the inverse map for link naming
  private_dns_zones_logical_names = { for k, v in var.vnet_private_dns_zones : v => k }
  nsg_rules                       = var.vnet_network_security_group_rules
  nsg_map                         = var.vnet_nsg_map
}

output "debug_vnet_cidr" {
  value = var.vnet_address_cidr
}

#################################################
# Create managed PostgreSQL and Redis databases #
#################################################

module "databases" {
  source = "./modules/databases"

  # Pass in global variables
  resource_prefix     = var.app_resource_name_prefix
  environment         = var.app_environment
  location            = var.app_location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.csb_resource_tags

  # Database variables
  postgres_admin_user   = var.db_postgres_admin_user
  postgres_sku          = var.db_postgres_sku
  postgres_storage_size = var.db_postgres_storage_size

  # Redis variables
  redis_subnet_id = module.network.subnet_ids["csec-private-service-subnet"] # Changed to a more appropriate subnet

}

###################################################################
# Create private endpoints for secured backend data communication #
###################################################################

module "security" {
  source = "./modules/security"

  # Pass in global variables
  resource_prefix     = var.app_resource_name_prefix
  environment         = var.app_environment
  location            = var.app_location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.csb_resource_tags

  # Pass in dependencies from other modules
  private_endpoints_subnet_id = module.network.subnet_ids["csec-private-service-subnet"]
  private_dns_zone_ids = {
    postgres = module.network.private_dns_zone_ids["postgres"]
  }
  postgres_server_id = module.databases.postgres_server_id

  depends_on = [
    module.network,
    module.databases
  ]
}

######################
# Create App-Service #
######################

locals {
  app_service_storage_account = "${var.app_resource_name_prefix}appservice${var.app_environment}v1"
}

module "app_service" {
  source = "./modules/app-service"

  # Pass in global variables
  resource_prefix     = var.app_resource_name_prefix
  environment         = var.app_environment
  location            = var.app_location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.csb_resource_tags

  # Storage account specific
  storage_account                  = local.app_service_storage_account
  storage_account_tier             = var.app_service_storage_account_tier
  storage_account_replication_type = var.app_service_storage_account_replication_type

  # Pass in app-service-specific variables
  os_type               = var.app_service_os_type
  plan_sku              = var.app_service_plan_sku
  py_version            = var.app_service_py_version
  flask_startup_command = var.app_service_flask_startup_command

  # Pass in dependencies from the network module
  subnet_id = module.network.subnet_ids["csec-app-service-subnet"]

  # App environment variables
  app_environment_vars = {
    "API_AUTH_TOKEN" : var.csec_api_auth_token
    "CACHE_TTL_SECONDS" : var.csec_api_cache_ttl_seconds
    "POSTGRES_HOST" : module.databases.postgres_server_fqdn
    "POSTGRES_PORT" : var.csec_api_postgres_port
    "POSTGRES_USER" : module.databases.postgres_admin_username
    "POSTGRES_PASSWORD" : module.databases.postgres_admin_password
    "POSTGRES_DB" : module.databases.postgres_db_name
    "POSTGRES_MAX_CONN" : var.csec_api_postgres_max_conn
    "REDIS_HOST" : module.databases.redis_ip_address
    "REDIS_PORT" : var.csec_api_redis_port
    "REDIS_USER" : "default"
    "REDIS_PASSWORD" : module.databases.redis_password
    "ALLOWED_ORIGIN" : var.csec_api_allowed_origin
  }

  # Wait for secuity and database modules
  depends_on = [
    module.security,
    module.databases
  ]
}
