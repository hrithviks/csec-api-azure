/*
Project     : CSB-API-Service Infrastructure Configuration
Module      : Terraform Root Configuration
Description : Root configuration for CSB-API-Service
Context     : Module Variables
*/

#################
# Basic Section #
#################

variable "app_resource_group_name" {
  type        = string
  description = "Main resource group to host the application."
}

variable "app_location" {
  description = "The Azure region where resources will be deployed."
  type        = string

  validation {
    condition     = contains(["southeastasia"], var.app_location)
    error_message = "Invalid location for the resources. Only 'southeastasia' is allowed."
  }
}

variable "app_resource_name_prefix" {
  description = "A prefix for all resource names."
  type        = string
  default     = "csec"
}

variable "app_environment" {
  description = "The deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.app_environment)
    error_message = "Invalid environment. Only 'dev', 'test' and 'prod' are allowed."
  }
}

############################
# Network Resource Section #
############################

variable "vnet_address_cidr" {
  description = "The CIDR address space for the VNet."
  type        = list(string)

  /* Placeholder for CIDR validation
  validation {
    condition = alltrue([
      for cidr in var.vnet_address_cidr : can(cidrnet(trimspace(cidr)))
    ])
    error_message = "Invalid CIDR representation."
  }*/
}

variable "vnet_subnets_map" {
  description = "The subnets to be created in the VNet."
  type = map(object({
    name             = string
    address_prefixes = list(string)
    delegations = optional(list(object({
      name         = string
      service_name = string
      actions      = list(string)
    })), [])
    private_endpoint_policies = string
  }))
}

variable "vnet_private_dns_zones" {
  description = "The private DNS zones associated with the private subnet."
  type        = map(string)
}

variable "vnet_nsg_map" {
  description = "A map of Network Security Groups to create and associate with subnets."
  type        = map(string)
}

variable "vnet_network_security_group_rules" {
  description = "The network security groups rules."
}

# DevOps VNet Peering
variable "devops_vnet_resource_group_name" {
  description = "The name of the resource group containing the existing DevOps VNet."
  type        = string
  default     = "csec-az-devops-rg"
}

variable "devops_vnet_name" {
  description = "The name of the existing DevOps VNet to peer with."
  type        = string
  default     = "csec-az-devops-vnet"
}

variable "devops_agent_subnet_address_prefix" {
  description = "The address prefix of the DevOps agent subnet (e.g., '10.1.1.0/24'). Used for the NSG rule."
  type        = string
  default     = "10.1.1.0/24"
}

#######################
# App-Service Section #
#######################

variable "app_service_plan_sku" {
  type        = string
  description = "The SKU for the App Service Plan. Minimum B1 required for VNet integration."
}

variable "app_service_storage_account_tier" {
  type        = string
  description = "The storage account tier for the App Service."
}

variable "app_service_storage_account_replication_type" {
  type        = string
  description = "The storage account replication type for the App Service."
}

variable "app_service_os_type" {
  type        = string
  description = "The OS type for the App Service Plan."
}

variable "app_service_flask_startup_command" {
  type        = string
  description = "The startup command for the Flask app."
}

# Environment variables for the CSB-API
variable "csec_api_auth_token" {
  type        = string
  description = "Authentication token for the API service."
  sensitive   = true
}

variable "csec_api_cache_ttl_seconds" {
  type        = number
  description = "Cache TTL in seconds for the API service."
  default     = 300
}

variable "csec_api_postgres_port" {
  type        = number
  description = "The port number for the PostgreSQL DB Server."
  default     = 5432
}

variable "csec_api_postgres_max_conn" {
  type        = number
  description = "The maximum allowed connections for the PostgreSQL DB Server."
  default     = 10
}

variable "csec_api_redis_port" {
  type        = number
  description = "The port number of the Redis database."
  default     = 6379
}

variable "csec_api_allowed_origin" {
  type        = string
  description = "The allowed origin for the API service."
  default     = "localhost"
}

# Container Registry variables

variable "app_ghcr_url" {
  type        = string
  description = "The URL of the Docker registry."
  default     = "https://ghcr.io"
}

variable "app_ghcr_user" {
  type        = string
  description = "The username for the private Docker registry."
  sensitive   = true
}

variable "app_ghcr_pswd" {
  type        = string
  description = "The password (or PAT) for the private Docker registry."
  sensitive   = true
}

variable "app_image_name" {
  type        = string
  description = "The URL of the private Docker image with the tag"
}

####################
# Database Section #
####################

variable "db_postgres_admin_user" {
  type        = string
  description = "The admin username for the PostgreSQL."
}

variable "db_postgres_sku" {
  type        = string
  description = "The SKU for the PostgreSQL DB service."
}

variable "db_postgres_storage_size" {
  type        = number
  description = "The storage size for the PostgreSQL DB service."
}

variable "db_redis_image_registry_user" {
  type        = string
  description = "The username for the Redis image registry."
}

variable "db_redis_image_registry_password" {
  type        = string
  description = "The password for the Redis image registry."
  sensitive   = true
}

variable "db_redis_image" {
  type        = string
  description = "The image for the Redis cache."
}
