/*
Project     : CSB-API-Service
Module      : Azure App-Service
Description : App-Service module configuration for CSB-API-Service
Context     : Module Main
*/

################################
# Storage account for logging  #
################################

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  tags                     = var.tags
}

################################
# App service plan resource    #
################################

resource "azurerm_service_plan" "main" {
  name                = "${var.resource_prefix}-asp-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  sku_name            = var.plan_sku
  tags                = var.tags
}

################################
# App service resource         #
################################

resource "azurerm_linux_web_app" "main" {
  name                = "${var.resource_prefix}-app-service-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = var.py_version
    }
    always_on = true
  }

  app_settings = var.app_environment_vars

  virtual_network_subnet_id = var.subnet_id

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITES_ENABLE_APP_SERVICE_STORAGE"],
    ]
  }

  tags = var.tags
}
