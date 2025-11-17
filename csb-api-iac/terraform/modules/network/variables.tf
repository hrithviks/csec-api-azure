/*
Project     : CSB-API-Service
Module      : Azure Network
Description : Network module configuration for CSB-API-Service
Context     : Module Variables
*/

###################
# Basic Variables #
###################

variable "resource_group_name" {
  description = "The name of the resource group to deploy resources into."
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string

  validation {
    condition     = contains(["southeastasia"], var.location)
    error_message = "Invalid location for the resources. Only 'southeastasia' is allowed."
  }
}

variable "resource_prefix" {
  description = "A prefix for resource names."
  type        = string
}

variable "environment" {
  description = "The deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Invalid environment. Only 'dev', 'test' and 'prod' are allowed."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
}

##################
# Vnet Variables #
##################

variable "vnet_address_space" {
  description = "The main address space for the VNet."
  type        = list(string)
}

variable "subnets_map" {
  type = map(object({
    name             = string
    address_prefixes = list(string)
    delegations = optional(list(object({ # Make delegations an optional list of objects
      name         = string
      service_name = string
      actions      = list(string)
    })), []) # Default to an empty list if not provided
    private_endpoint_policies = string
  }))
  description = "A map of subnet configurations."
}

variable "private_dns_zones" {
  description = "A map of logical names to Private DNS Zone FQDNs to create."
  type        = map(string)
}

variable "private_dns_zones_logical_names" {
  description = "A map of Private DNS Zone FQDNs to their logical names (for link naming)."
  type        = map(any)
}

variable "nsg_map" {
  description = "A map of Network Security Groups to create. The value is the key of the subnet to associate it with, or null."
  type        = map(string)
}

variable "nsg_rules" {
  type = map(object({
    nsg_key                    = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = optional(string, null)       # Make optional, default to null
    destination_port_ranges    = optional(list(string), null) # Make optional, default to null
    source_address_prefix      = optional(string, null)       # Make optional, default to null
    destination_address_prefix = string
    source_subnet_key          = optional(string, null) # Make optional, default to null
  }))
  description = "A map of NSG rules. The key is the unique rule name."
}
