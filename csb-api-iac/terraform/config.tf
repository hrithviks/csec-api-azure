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
  # This block constrains the Terraform CLI version.
  # The '~>' operator allows for patch releases but locks the major and minor
  # versions, ensuring no breaking changes from a new minor release are
  # introduced. This is set based on the version in the Dockerfile and local
  # environment.
  required_version = "~> 1.14" # Allows versions >= 1.14.0 and < 1.15.0

  required_providers {
    # This block defines the required providers and their version constraints.
    # Pinning provider versions is critical for preventing unexpected changes in
    # provider behavior that could break the configuration.

    azurerm = {
      source = "hashicorp/azurerm"
      # Allows versions >= 4.54.0 and < 4.55.0
      version = "~> 4.54.0"
    }

    random = {
      source = "hashicorp/random"
      # Allows versions >= 3.7.2 and < 3.8.0
      version = "~> 3.7.2"
    }
  }
}

provider "azurerm" {
  # In a CI/CD environment, a Service Principal is used for authentication.
  # This block tells the provider to use the credentials exposed as
  # environment variables by the Azure CLI task (e.g., ARM_CLIENT_ID, ARM_TENANT_ID).
  use_cli = false
  features {
  }
}
