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
  default     = "csec-az-devops-rg"
}

variable "vnet_name" {
  description = "The name of the virtual network to be created."
  type        = string
  default     = "csec-az-devops-vnet"
}

variable "snet_name" {
  description = "The name of the subnet to be created."
  type        = string
  default     = "csec-az-devops-snet"
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

resource "azurerm_resource_group" "devops_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.resource_tags
}

resource "azurerm_virtual_network" "devops_vnet" {
  name                = var.vnet_name
  address_space       = local.vnet_address_space
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  tags                = local.resource_tags
}

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

resource "azurerm_storage_container" "state_container" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.terraform_state.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "sp_storage_access" {
  scope                = azurerm_storage_account.terraform_state.id
  role_definition_name = var.storage_role_name
  principal_id         = var.service_principal_object_id
}
