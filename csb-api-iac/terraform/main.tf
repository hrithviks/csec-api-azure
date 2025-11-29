/*
Project     : CSB-API-Service Infrastructure Configuration
Module      : Terraform Root Configuration
Description : Root configuration for CSB-API-Service
Context     : Module Main

NOTE: This configuration is designed as a demonstration of a secure, modular
Azure deployment. It prioritizes simplicity and clarity to showcase core
infrastructure-as-code concepts. For a production-grade environment, several
key architectural improvements would be necessary, as documented within the
individual modules.

# Key Architectural Decisions for this Demo:

- Simplicity over HA: Services like Redis are self-managed in Azure Container
  Instances (ACI) for simplicity, rather than using the more complex and
  costly Azure Cache for Redis. The PostgreSQL server is a single instance
  with limited redundancy.

- Limited Scalability: The chosen service tiers (e.g., Basic for App Service
  Plan) and architectures (single-instance databases) are cost-effective for a
  demo but do not support auto-scaling or high-throughput scenarios.

- Simplified Secret Management: Passwords are generated at runtime and passed
  as environment variables. A production setup would use Azure Key Vault with
  Managed Identities for secure secret storage and retrieval.

- Basic Observability: This setup relies on native Azure tools for viewing
  logs and metrics on a per-service basis. A production-grade system would
  implement centralized log aggregation (e.g., via a Log Analytics Workspace)
  for more effective correlation, analysis, and alerting across the entire
  application stack.

# Module Structure and Dependencies:

The infrastructure is logically grouped into modules to promote reusability and
separation of concerns. The dependency flow is as follows:

1. `network`: Forms the foundation, creating the VNet and subnets.

2. `databases`: Deploys PostgreSQL and Redis, 
    depending on the `network` module for subnet placement.

3. `security`: Creates Private Endpoints, depending on `network` 
    (for subnet/DNS) and `databases` (for the target resource).

4. `app_service`: Deploys the application, depending on all other modules 
    for network integration and database connection details.
*/

################################
# Reusable local configuration #
################################

locals {
  csb_resource_tags = {
    environment     = var.app_environment
    contact_info    = "csbapiadmin@csecbridge.org"
    app_name        = "csb-api-app"
    build_timestamp = formatdate("YYYY-MM-DD'T'HH:MM:ssZ", timestamp())
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

  # DevOps VNet Peering
  enable_devops_vnet_peering         = true
  devops_vnet_resource_group_name    = var.devops_vnet_resource_group_name
  devops_vnet_name                   = var.devops_vnet_name
  devops_agent_subnet_address_prefix = var.devops_agent_subnet_address_prefix
}

output "debug_vnet_cidr" {
  value = var.vnet_address_cidr
}

#################################################
# Create managed PostgreSQL and Redis databases #
#################################################

locals {
  db_redis_api_user = "${var.app_resource_name_prefix}-redis-user-${var.app_environment}"
}

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
  redis_subnet_id               = module.network.subnet_ids["csec-private-service-subnet"]
  redis_image                   = "ghcr.io/${var.db_redis_image_registry_user}/${var.db_redis_image}"
  redis_image_registry_password = var.db_redis_image_registry_password
  redis_image_registry_user     = var.db_redis_image_registry_user
  redis_csb_api_user            = local.db_redis_api_user
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
  private_endpoints_subnet_id = module.network.subnet_ids["private_endpoints"]
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
  os_type  = var.app_service_os_type
  plan_sku = var.app_service_plan_sku

  # Container variables
  docker_server_url     = var.app_ghcr_url
  docker_image_name     = var.app_image_name
  docker_username       = var.app_ghcr_user
  docker_password       = var.app_ghcr_pswd
  flask_startup_command = var.app_service_flask_startup_command

  # Pass in dependencies from the network module
  subnet_id = module.network.subnet_ids["csec-app-service-subnet"]

  # App environment variables
  app_environment_vars = {
    "API_AUTH_TOKEN"    = var.csec_api_auth_token
    "CACHE_TTL_SECONDS" = var.csec_api_cache_ttl_seconds
    "POSTGRES_HOST"     = module.databases.postgres_server_fqdn
    "POSTGRES_PORT"     = var.csec_api_postgres_port
    "POSTGRES_USER"     = module.databases.postgres_admin_username
    "POSTGRES_PASSWORD" = module.databases.postgres_admin_password
    "POSTGRES_DB"       = module.databases.postgres_db_name
    "POSTGRES_MAX_CONN" = var.csec_api_postgres_max_conn
    "REDIS_HOST"        = module.databases.redis_ip_address
    "REDIS_PORT"        = var.csec_api_redis_port
    "REDIS_USER"        = local.db_redis_api_user
    "REDIS_PASSWORD"    = module.databases.redis_csb_api_user_password
    "ALLOWED_ORIGIN"    = var.csec_api_allowed_origin
  }

  # Wait for secuity and database modules
  depends_on = [
    module.security,
    module.databases
  ]
}
