/*
Project     : CSB-API-Service Infrastructure Configuration
Module      : Root Configuration
Description : Root configuration for CSB-API-Service
Context     : AzureRM Config
*/

/*
NOTE: This is a simple configuration for AzureRM.
For an enterprise-grade CI/CD pipeline, following enhancements should be 
introduced for improved security, stability, and reproducibility:

1.  Explicit Provider Authentication: This configuration relies on ambient
    credentials (e.g., from Azure CLI). In a CI/CD environment, it is more
    secure and explicit to configure the provider with a dedicated Service
    Principal. This can be done using environment variables (ARM_CLIENT_ID,
    ARM_CLIENT_SECRET, etc.) or, for greater security, by using OIDC Connect
    for passwordless authentication from platforms like GitHub Actions.

2.  Explicit Feature Flags: The `features {}` block is currently empty,
    relying on the provider's default behaviors. In production, enable explicit 
    configuration for feature flags (e.g., for Key Vault or Resource Groups)
    to ensure consistent behavior across different provider versions.
*/

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  # In a CI/CD environment, we use a Service Principal for authentication.
  # This block tells the provider to use the credentials exposed as environment
  # variables by the Azure CLI task (e.g., ARM_CLIENT_ID, ARM_TENANT_ID).
  use_cli = false
  features {
  }
}
