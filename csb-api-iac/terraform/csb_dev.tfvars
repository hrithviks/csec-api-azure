/*
Project     : CSB-API-Service
Module      : Terraform Root Configuration
Description : Root configuration for CSB-API-Service
Context     : Dev Environment Variables
*/

################
# Basic Values #
################
app_resource_group_name  = "csec-app-rg"
app_location             = "southeastasia"
app_resource_name_prefix = "csec"
app_environment          = "dev"

#####################
# Networking Values #
#####################
vnet_address_cidr = ["10.0.0.0/16"]
vnet_subnets_map = {

  # Subnet 1: For the App Service, with delegation for app service
  csec-app-service-subnet = {
    name             = "csec-app-service-subnet"
    address_prefixes = ["10.0.1.0/24"]
    delegations = [
      {
        name         = "app-service-delegation"
        service_name = "Microsoft.Web/serverFarms"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    ]
    private_endpoint_policies = "Enabled"
  },

  # Subnet 2: For Private Endpoints, with delegation for container instance
  csec-private-service-subnet = {
    name             = "csec-private-service-subnet"
    address_prefixes = ["10.0.2.0/24"]
    delegations = [
      {
        name         = "container-instance-delegation"
        service_name = "Microsoft.ContainerInstance/containerGroups"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    ]
    private_endpoint_policies = "Enabled" # Policies can be enabled here
  },

  # Subnet 3: For Private Endpoints
  private_endpoints = {
    name                      = "csec-pep-subnet-dev"
    address_prefixes          = ["10.0.3.0/24"]
    delegations               = []
    private_endpoint_policies = "Disabled" # Must be disabled for Private Endpoints
  }
}

vnet_private_dns_zones = {
  "postgres" = "privatelink.postgres.database.azure.com"
}

vnet_nsg_map = {
  "csec-app-service-nsg"     = "csec-app-service-subnet"
  "csec-private-service-nsg" = "csec-private-service-subnet"
  "csec-pep-nsg"             = "private_endpoints"
}

vnet_network_security_group_rules = {

  # Rule 2: Allow Redis traffic from the App Service subnet
  "Allow-Redis-In" = {
    nsg_key                    = "csec-private-service-nsg" # Fixed to private service
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6379"
    destination_port_ranges    = null # place-holder for multi-port rule
    source_address_prefix      = null # dynamically set to subnet's address prefix by default
    destination_address_prefix = "*"
    source_subnet_key          = "csec-app-service-subnet"
  },

  # Rule 3: Allow inbound HTTPS traffic to the App Service
  "Allow-HTTPS-In" = {
    nsg_key                    = "csec-app-service-nsg" # Fixed to app service
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    destination_port_ranges    = null
    source_address_prefix      = "Internet" # Standard tag for internet traffic
    destination_address_prefix = "*"
    source_subnet_key          = null
  },

  # Rule 4: Deny all inbound traffic to the private endpoint subnet by default
  "Deny-All-Inbound-PEP" = {
    nsg_key                    = "csec-pep-nsg"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    destination_port_ranges    = null
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    source_subnet_key          = null
  },

  # Rule 5: Allow Postgres traffic from App Service Subnet to Private Endpoint Subnet
  "Allow-Postgres-From-App-To-PEP" = {
    nsg_key                    = "csec-pep-nsg" # Apply to the Private Endpoint NSG
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    destination_port_ranges    = null
    source_address_prefix      = null
    destination_address_prefix = "*" # Target the entire destination subnet
    source_subnet_key          = "csec-app-service-subnet"
  }
}

######################
# App-Service Values #
######################
app_service_storage_account_tier             = "Standard"
app_service_storage_account_replication_type = "LRS"
app_service_os_type                          = "Linux"
app_service_plan_sku                         = "B1"
app_service_flask_startup_command            = "pip install -r requirements.txt && gunicorn --bind=0.0.0.0 --workers=2 main:app"
app_service_py_version                       = "3.12"

# API environment variables
csec_api_auth_token        = null # For demo only. Secrets should be outside variable file.
csec_api_cache_ttl_seconds = 300
csec_api_postgres_port     = 5432
csec_api_postgres_max_conn = 10
csec_api_redis_port        = 6379
csec_api_allowed_origin    = "localhost"

###################
# Database Values #
###################
db_postgres_admin_user   = "csec_psql_admin_user" # For demo only. Secrets should be outside variable file.
db_postgres_storage_size = 32768
db_postgres_sku          = "B_Standard_B1ms"

# For Redis, sticking to default values.

###################
# Security Values #
###################
