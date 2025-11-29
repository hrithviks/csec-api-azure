/*
Project     : CSB-API-Service Infrastructure Configuration
Module      : Azure Network
Description : Network module configuration for CSB-API-Service
Context     : Module Main
*/

#################################
# Main virtual network resource #
#################################

resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_prefix}-vnet-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space # CIDR for the Vnet
  tags                = var.tags
}

###########
# Subnets #
###########

resource "azurerm_subnet" "main" {

  # Create one subnet for each item in the var.subnets map
  for_each = var.subnets_map

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes

  # Must be set to disable to allow deployment of private end points.
  private_endpoint_network_policies = each.value.private_endpoint_policies

  # Dynamic delagation block to allow Azure services to deploy into the subnet.
  # E.g. Permission for AzureApp Service to allow placing the resource in this subnet
  dynamic "delegation" {

    # Conditional assignment for dynamic block
    # Dynamic block is active only if there's a valid list object for delegrations
    for_each = each.value.delegations == null ? [] : each.value.delegations

    content {

      # Based on the object attribute
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

###################################################
# Private DNS zone resources for backend services #
###################################################

# Private DNS Zone
resource "azurerm_private_dns_zone" "main" {

  # For all private DNS zones
  for_each = var.private_dns_zones

  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Private DNS Zone Link
resource "azurerm_private_dns_zone_virtual_network_link" "main" {

  # Use for_each to create a link for each zone(created above)
  for_each = azurerm_private_dns_zone.main

  # Create a unique name for the link
  name = "${azurerm_virtual_network.main.name}-${each.key}-link"

  resource_group_name   = var.resource_group_name
  private_dns_zone_name = each.value.name # Reference the name of the zone
  virtual_network_id    = azurerm_virtual_network.main.id
}

locals {
  # Dynamically create the NSG rule for the DevOps agent if peering is enabled.
  # This creates a map with one entry ("Allow-DevOps-Agent-Inbound-Postgres") if true, or an empty map if false.
  devops_agent_nsg_rule = var.enable_devops_vnet_peering ? {
    "Allow-DevOps-Agent-Inbound-Postgres" = {
      nsg_key                    = "csec-pep-nsg"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      destination_port_ranges    = null
      source_address_prefix      = var.devops_agent_subnet_address_prefix
      destination_address_prefix = "*"
      source_subnet_key          = null
      destination_ip_var         = null
    }
  } : {}

  # Merge the dynamically created rule with the rules passed in from the variable file.
  all_nsg_rules = merge(var.nsg_rules, local.devops_agent_nsg_rule)
}

######################################################################
# DevOps VNet Peering and Connectivity (Conditional)                 #
# Creates peering, DNS links, and NSG rules to the DevOps agent VNet #
######################################################################

# Look up the existing DevOps VNet using the provided name and resource group.
# This data source will only be queried if peering is enabled.
data "azurerm_virtual_network" "devops_vnet" {
  count               = var.enable_devops_vnet_peering ? 1 : 0
  name                = var.devops_vnet_name
  resource_group_name = var.devops_vnet_resource_group_name
}

# 1. VNet Peering: App VNet -> DevOps VNet
resource "azurerm_virtual_network_peering" "app_to_devops" {
  count                     = var.enable_devops_vnet_peering ? 1 : 0
  name                      = "peer-app-to-devops"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.main.name
  remote_virtual_network_id = data.azurerm_virtual_network.devops_vnet[0].id
}

# 1. VNet Peering: DevOps VNet -> App VNet (return path)
resource "azurerm_virtual_network_peering" "devops_to_app" {
  count                     = var.enable_devops_vnet_peering ? 1 : 0
  name                      = "peer-devops-to-app"
  resource_group_name       = data.azurerm_virtual_network.devops_vnet[0].resource_group_name
  virtual_network_name      = data.azurerm_virtual_network.devops_vnet[0].name
  remote_virtual_network_id = azurerm_virtual_network.main.id
}

# 2. Private DNS Zone Link: Link the PostgreSQL DNS zone to the DevOps VNet.
# This allows the DevOps agent to resolve the private IP of the database.
resource "azurerm_private_dns_zone_virtual_network_link" "devops_postgres_dns_link" {
  count                 = var.enable_devops_vnet_peering && contains(keys(azurerm_private_dns_zone.main), "postgres") ? 1 : 0
  name                  = "${var.devops_vnet_name}-postgres-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.main["postgres"].name
  virtual_network_id    = data.azurerm_virtual_network.devops_vnet[0].id

  # Ensure this runs after the peering is established.
  depends_on = [azurerm_virtual_network_peering.app_to_devops]
}

####################################
# Network security group resources #
####################################

/* Note: This network configuration provides a solid foundation. For a
full-scale, enterprise-grade production environment, consider the following
architectural enhancements:

- Centralized Egress Control: For enhanced security and monitoring, all
  outbound traffic from private subnets should be routed through a central
  point. This can be achieved by associating a Route Table with the subnets
  that directs traffic to an Azure Firewall or a NAT Gateway. This allows for
  consistent IP-based allow-listing and centralized logging of outbound flows.

- Ingress Traffic Management: For web-facing applications, an Azure Application
  Gateway with a Web Application Firewall (WAF) should be used as the entry
  point to filter for common web vulnerabilities (e.g., SQL injection, XSS).
*/

# NSG for the Private service subnet
resource "azurerm_network_security_group" "main" {
  for_each            = var.nsg_map
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# NSG security rules
resource "azurerm_network_security_rule" "main" {
  for_each = local.all_nsg_rules
  name     = each.key # Use the map key as the rule name

  # Use the 'nsg_key' from the variable to look up the correct NSG ID
  network_security_group_name = azurerm_network_security_group.main[each.value.nsg_key].name
  resource_group_name         = var.resource_group_name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  destination_port_ranges     = each.value.destination_port_ranges

  # Dynamic Source: Use a subnet's address if 'source_subnet_key' is set,
  # otherwise use the provided 'source_address_prefix' (e.g., "Internet")
  source_address_prefixes = each.value.source_subnet_key != null ? azurerm_subnet.main[each.value.source_subnet_key].address_prefixes : null
  source_address_prefix   = each.value.source_subnet_key == null ? each.value.source_address_prefix : null

  # The destination is now the entire destination subnet, or a specific prefix like '*'
  destination_address_prefix = each.value.destination_address_prefix
  # Set explicit dependency on the NSGs before attempting to create the rules
  depends_on = [
    azurerm_network_security_group.main
  ]
}

# Associate NSGs to Subnets
resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = { for k, v in var.nsg_map : k => v if v != null }

  subnet_id                 = azurerm_subnet.main[each.value].id
  network_security_group_id = azurerm_network_security_group.main[each.key].id
}
