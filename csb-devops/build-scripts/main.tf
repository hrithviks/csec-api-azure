/*
Project     : CSEC-API-Service DevOps Configuration
Module      : DevOps Resources
Description : This Terraform configuration provisions the necessary resources
              for the DevOps environment, including the storage account for
              managing Terraform's remote state. It is intended to be run
              with a local backend to bootstrap the remote state.
*/

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.5"
    }
  }
  # This configuration uses a local backend because it is responsible for
  # provisioning the remote state backend itself. Subsequent Terraform
  # configurations for the application infrastructure should use the
  # `azurerm` backend configured to use the storage account created here.
  backend "local" {}
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  description = "The name of the resource group to be created."
  type        = string
  default     = "csec-devops-rg"
}

variable "vnet_name" {
  description = "The name of the virtual network to be created."
  type        = string
  default     = "csec-devops-vnet"
}

variable "snet_name" {
  description = "The name of the subnet to be created."
  type        = string
  default     = "csec-devops-snet"
}

variable "location" {
  description = "The Azure region where the resources will be deployed."
  type        = string
  default     = "southeastasia"
}

variable "service_principal_object_id" {
  description = "The Object ID of the Azure DevOps service principal that requires access to the storage account."
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "The Tenant ID of the Azure subscription."
  type        = string
  sensitive   = true
}

variable "storage_account_name" {
  description = "The name of the storage account to be created."
  type        = string
  default     = "csecinfracontainer"
}

variable "container_name" {
  description = "The name of the container to be created."
  type        = string
  default     = "csec-infra-state-v1"
}

variable "storage_role_name" {
  description = "The name of the storage role to be assigned to the service principal."
  type        = string
  default     = "Storage Blob Data Contributor"
}

locals {

  # Network Resources
  vnet_address_space = ["10.1.0.0/16"]
  snet_address_space = ["10.1.1.0/24"]

  # Tags
  resource_tags = {
    environment = "devops"
    contact     = "devops@csecbridge.org"
    created_at  = formatdate("YYYY-MM-DD'T'HH:MM:ssZ", timestamp())
  }
}

# Creates the primary resource group for core DevOps infrastructure.
# This group contains resources essential for the CI/CD process, such as the
# Terraform state storage account and its associated networking components.
resource "azurerm_resource_group" "devops_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.resource_tags
}

# Creates a dedicated resource group for secret management resources.
# Centralizing Key Vaults in this group improves security and organization,
# separating sensitive assets from the main application infrastructure.
resource "azurerm_resource_group" "secrets_rg" {
  name     = "csec-secrets-rg"
  location = var.location
  tags     = local.resource_tags
}

# Provisions the virtual network for the DevOps environment.
# This VNet provides a private and secure network space for the resources
# that support the CI/CD workflow, such as the agent pool or storage accounts.
resource "azurerm_virtual_network" "devops_vnet" {
  name                = var.vnet_name
  address_space       = local.vnet_address_space
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  tags                = local.resource_tags
}

# Defines a subnet within the DevOps virtual network.
# This subnet is used to isolate resources and apply specific network security rules.
# The 'Microsoft.Storage' service endpoint is enabled to allow resources within
# this subnet to securely access the Terraform state storage account via the
# Azure backbone network, bypassing the public internet.
resource "azurerm_subnet" "devops_snet" {
  name                 = var.snet_name
  resource_group_name  = azurerm_resource_group.devops_rg.name
  virtual_network_name = azurerm_virtual_network.devops_vnet.name
  address_prefixes     = local.snet_address_space
  service_endpoints    = ["Microsoft.Storage"]

  depends_on = [
    azurerm_virtual_network.devops_vnet
  ]
}

# Provisions the Azure Storage Account that will serve as the remote backend
# for storing Terraform state files. Using a remote backend is critical for
# team collaboration and for running Terraform in automated CI/CD pipelines.
# Network access is restricted to the DevOps subnet for enhanced security.
resource "azurerm_storage_account" "terraform_state" {
  name                = var.storage_account_name
  resource_group_name = azurerm_resource_group.devops_rg.name
  location            = azurerm_resource_group.devops_rg.location
  account_tier        = "Standard"

  # For enterprise products, consider GRS or ZRS for improved data resiliency.
  account_replication_type = "LRS"

  # Network access is restricted to enhance security.
  # Public network access must be enabled to allow firewall rules -
  # IP rules and VNet Service Endpoints to take effect.
  # Access is then restricted by the `network_rules` block below, where the default action is to deny.
  public_network_access_enabled = true

  network_rules {
    default_action = "Deny"
    # Allows trusted Azure services to bypass network rules.
    bypass = ["AzureServices"]

    # Grants access exclusively from the specified Subnet
    # Note: The Microsoft.Storage service endpoint must be enabled 
    # on the subnet provided in 'allowed_subnet_id'.
    virtual_network_subnet_ids = [azurerm_subnet.devops_snet.id]
  }

  tags = local.resource_tags

  depends_on = [
    azurerm_subnet.devops_snet
  ]
}

# Creates the blob container within the storage account.
# This container is the specific location where Terraform will store the
# 'tfstate' files for each environment.
resource "azurerm_storage_container" "state_container" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.terraform_state.id
  container_access_type = "private"
}

# Assigns the 'Storage Blob Data Contributor' role to the pipeline's service principal.
# This role assignment is essential as it grants the CI/CD pipeline the necessary
# permissions to read from and write to the Terraform state files stored in the
# blob container.
resource "azurerm_role_assignment" "sp_storage_access" {
  scope                = azurerm_storage_account.terraform_state.id
  role_definition_name = var.storage_role_name
  principal_id         = var.service_principal_object_id
}

# Creates the Azure Key Vault for the 'dev' environment.
# This vault will be used to securely store and manage secrets, such as database
# passwords and API keys, that are generated or required by the infrastructure.
resource "azurerm_key_vault" "dev_vault" {
  name                = "csec-vault-dev"
  location            = azurerm_resource_group.secrets_rg.location
  resource_group_name = azurerm_resource_group.secrets_rg.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.service_principal_object_id

    # Grant permissions for the service principal to manage secrets
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  }

  tags = local.resource_tags
}
