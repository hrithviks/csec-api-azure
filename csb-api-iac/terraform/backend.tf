/*
Project     : CSB-API-Service
Module      : Root Configuration
Description : Root configuration for CSB-API-Service
Context     : Backend Configuration
*/


terraform {
  backend "azurerm" {
    resource_group_name  = "csb-az-terraform"
    storage_account_name = "csbapitfstatev1"
    container_name       = "csb-tfstate"
    key                  = "terraform.tfstate" # This will be the name of the state file in the container
  }
}
