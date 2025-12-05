/*
Project     : CSB-API-Service Infrastructure Configuration
Module      : Azure Databases
Description : Databases module configuration for CSB-API-Service
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

##########################
# PostgreSQL Variables   #
##########################

variable "postgres_admin_password_chars" {
  type        = number
  description = "The number of characters for the PostgreSQL admin password."
  default     = 16
}

variable "postgres_db_version" {
  type        = string
  description = "The version for the PostgreSQL DB service."
  default     = "14"
}

variable "postgres_sku" {
  type        = string
  description = "The SKU for the PostgreSQL DB service."
}

variable "postgres_storage_size" {
  type        = number
  description = "The storage size in MB for the PostgreSQL DB service."
}

variable "postgres_admin_user" {
  type        = string
  description = "The admin username for the PostgreSQL."
}

variable "postgres_backup_retention_days" {
  type        = number
  description = "The backup retention days for the PostgreSQL DB service."
  default     = 7
}

variable "postgres_charset" {
  type        = string
  description = "The charset for the PostgreSQL database."
  default     = "UTF8"
}

variable "postgres_collation" {
  type        = string
  description = "The collation for the PostgreSQL database."
  default     = "en_US.utf8"
}

###################
# Redis Variables #
###################

variable "redis_subnet_id" {
  type        = string
  description = "The ID of the subnet for the Redis cache."
}

variable "redis_image" {
  type        = string
  description = "The image for the Redis cache."
}

variable "redis_image_registry_user" {
  type        = string
  description = "The username for the Redis image registry."
}

variable "redis_image_registry_password" {
  type        = string
  description = "The password for the Redis image registry."
}

variable "redis_admin_password_chars" {
  type        = number
  description = "The number of characters for the Redis admin password."
  default     = 16
}

variable "redis_cpu" {
  type        = string
  description = "The CPU for the Redis cache."
  default     = "0.5"
}

variable "redis_memory" {
  type        = string
  description = "The memory for the Redis cache."
  default     = "0.5"
}

variable "redis_csb_api_user" {
  type        = string
  description = "The username for the Redis csb-api user."
}
