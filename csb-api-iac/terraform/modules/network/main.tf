/*
Project     : CSB-API-Service
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

####################################
# Network security group resources #
####################################

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
  for_each = var.nsg_rules
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
  destination_address_prefix  = each.value.destination_address_prefix

  # Dynamic Source: Use a subnet's address if 'source_subnet_key' is set,
  # otherwise use the provided 'source_address_prefix' (e.g., "Internet")
  source_address_prefixes = each.value.source_subnet_key != null ? azurerm_subnet.main[each.value.source_subnet_key].address_prefixes : null
  source_address_prefix   = each.value.source_subnet_key == null ? each.value.source_address_prefix : null

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
