/*
Project     : CSB-API-Service
Module      : Azure App-Service
Description : App-Service module configuration for CSB-API-Service
Context     : Module Variables
*/

###################
# Basic Variables #
###################

variable "resource_prefix" {
  type        = string
  description = "A prefix for all resource names to ensure uniqueness."
}

variable "environment" {
  description = "The deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Invalid environment. Only 'dev', 'test' and 'prod' are allowed."
  }
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string

  validation {
    condition     = contains(["southeastasia"], var.location)
    error_message = "Invalid location for the resources. Only 'southeastasia' is allowed."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group to deploy resources into."
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
}

#########################
# App-Service Variables #
#########################

variable "os_type" {
  type        = string
  description = "The operating system type for the App Service."

  validation {
    condition     = contains(["Linux", "Windows", "WindowsContainer"], var.os_type)
    error_message = "Invalid OS type. Operating system must be one of 'Linux', 'Windows' or 'WindowsContainer'."
  }
}

variable "plan_sku" {
  type        = string
  description = "The SKU for the App Service Plan."

  validation {
    condition     = contains(["B1", "B2", "B3"], var.plan_sku)
    error_message = "Invalid SKU option. Must be a low-cost option, and basic due to VNet integration."
  }
}

variable "py_version" {
  type        = string
  description = "The Python version for the application."

  validation {
    condition     = contains(["3.12", "3.11", "3.10"], var.py_version)
    error_message = "Invalid Python version. It must be greater than or equal to 3.10."
  }
}

variable "storage_account" {
  type        = string
  description = "The storage account for App Service logs."
}

variable "storage_account_tier" {
  type        = string
  description = "The storage account tier for App Service logs."
  default     = "Standard"

  validation {
    condition     = contains(["Standard"], var.storage_account_tier)
    error_message = "Invalid storage tier. Only 'Standard' account is allowed."
  }
}

variable "storage_account_replication_type" {
  type        = string
  description = "The storage account replication type."
  default     = "LRS"

  validation {
    condition     = contains(["LRS"], var.storage_account_replication_type)
    error_message = "Invalid storage replication type. Only 'LRS' is allowed."
  }

}

variable "subnet_id" {
  type        = string
  description = "The resource ID of the subnet to integrate the App Service with."
}

variable "flask_startup_command" {
  type        = string
  description = "The startup command for the Flask app."
}

variable "app_environment_vars" {
  type        = map(any)
  description = "The map of all environment variables for the application."
  sensitive   = true

  validation {
    condition = alltrue([
      for key in [
        "API_AUTH_TOKEN",
        "CACHE_TTL_SECONDS",
        "POSTGRES_HOST",
        "POSTGRES_PORT",
        "POSTGRES_USER",
        "POSTGRES_PASSWORD",
        "POSTGRES_DB",
        "POSTGRES_MAX_CONN",
        "REDIS_HOST",
        "REDIS_PORT",
        "REDIS_PASSWORD",
        "ALLOWED_ORIGIN"
      ] :
      # 1. Check if the key exists in the map
      can(var.app_environment_vars[key]) &&
      # 2. Check if its value is not an empty string
      var.app_environment_vars[key] != ""
    ])
    error_message = "The 'app_environment_vars' variable must contain all required keys, and they must not be null or empty."
  }
}
