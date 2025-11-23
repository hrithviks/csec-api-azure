/*
Project     : CSB-API-Service DevOps Configuration
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
      version = "~> 3.0"
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

variable "allowed_subnet_id" {
  description = "The resource ID of the subnet that is allowed to access the storage account. Used for developer access from a VM."
  type        = string
}

data "azurerm_resource_group" "devops_rg" {
  name = "csb-az-devops-rg"
}

resource "azurerm_storage_account" "terraform_state" {
  name                = "csbinfrastatev1"
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  location            = data.azurerm_resource_group.devops_rg.location
  account_tier        = "Standard"
  # For production environments, consider GRS or ZRS for improved data resiliency.
  account_replication_type = "LRS"

  # Network access is restricted to enhance security.
  # Public network access must be enabled to allow firewall rules (IP rules and VNet Service Endpoints) to take effect.
  # Access is then restricted by the `network_rules` block below, where the default action is to deny.
  public_network_access_enabled = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"] # Allows trusted Azure services to bypass network rules.

    # Grants access exclusively from the specified Subnet
    # Note: The Microsoft.Storage service endpoint must be enabled on the subnet provided in 'allowed_subnet_id'.
    virtual_network_subnet_ids = [
      var.allowed_subnet_id
    ]
  }

  tags = {
    environment = "devops"
    purpose     = "Terraform State"
  }
}
