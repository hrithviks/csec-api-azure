/*
Project     : CSB-API-Service
Module      : Azure Security
Description : Security module configuration for CSB-API-Service
Context     : Module Variables
*/

###################
# Basic Variables #
###################

variable "resource_prefix" {
  type        = string
  description = "A prefix for all resource names."
}

variable "environment" {
  type        = string
  description = "The deployment environment name."
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group to deploy into."
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
}

#####################
# Service Variables #
#####################

variable "private_endpoints_subnet_id" {
  type        = string
  description = "The ID of the subnet dedicated to Private Endpoints."
}

variable "private_dns_zone_ids" {
  type        = map(string)
  description = "A map of logical names to Private DNS Zone IDs."
}

variable "postgres_server_id" {
  type        = string
  description = "The resource ID of the PostgreSQL Flexible Server."
}
