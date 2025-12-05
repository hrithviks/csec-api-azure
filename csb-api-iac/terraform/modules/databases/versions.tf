# Defines version constraints for the Terraform CLI and providers used in this module.
# Pinning versions ensures consistent behavior and prevents breaking changes.

terraform {
  required_version = "~> 1.14"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.54"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}
