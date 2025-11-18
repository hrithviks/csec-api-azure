/*
Project     : CSB-API-Service Infrastructure Configuration
Module      : Root Configuration
Description : Root configuration for CSB-API-Service
Context     : AzureRM Config
*/

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0" # Pins to a recent stable version
    }
  }
}

provider "azurerm" {
  features {

  }

  # Placeholder for pipeline execution.
}
