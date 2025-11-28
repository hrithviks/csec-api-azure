/*
Project     : CSB-API-Service Infrastructure Configuration
Module      : Azure App-Service
Description : App-Service module configuration for CSB-API-Service
Context     : Module Main
*/

###############################
# Storage account for logging #
###############################

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  tags                     = var.tags
}

#############################
# App service plan resource #
#############################

resource "azurerm_service_plan" "main" {
  name                = "${var.resource_prefix}-asp-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  sku_name            = var.plan_sku
  tags                = var.tags
}

########################
# App service resource #
########################

/* Note: This App Service configuration is suitable for stateless applications.
For more complex, stateful, or high-security production workloads, consider
the following architectural enhancements:

- Data Persistence for Stateful Apps: The default App Service storage is
  non-persistent across restarts and scaling events. For stateful applications
  requiring persistent storage, mount an Azure File Share to the App Service
  using the `storage_account` block within the `site_config`.

- Secure API Configuration: To restrict access to the App Service from the
  public internet, a Private Endpoint can be created. This makes the app
  accessible only from within its virtual network. For advanced API security,
  rate limiting, and lifecycle management, place Azure API Management in front
  of the App Service.

- Advanced Logging and Monitoring: While a storage account is provisioned,
  for production-grade observability, configure Diagnostic Settings to stream
  logs to an Azure Log Analytics Workspace. Additionally, integrating
  Application Insights provides deep performance monitoring, distributed
  tracing, and exception tracking.

- Multi-Container Deployments (Sidecars): For complex scenarios, App Service
  supports deploying multiple containers using Docker Compose. This is ideal
  for running sidecar containers for tasks like logging, monitoring, or as
  service mesh proxies alongside the main application.

- Managed Identity Integration: This App Service is configured with a
  System-Assigned Managed Identity. For enhanced security, this identity
  should be granted access to other Azure services (e.g., Key Vault,
  PostgreSQL, Storage Accounts). This allows the application to authenticate
  securely without managing or storing any credentials in app settings.

- Securing Environment Variables: Storing secrets directly in `app_settings`
  is not recommended for production. Instead, secrets should be stored in
  Azure Key Vault. The App Service can then use its Managed Identity to fetch
  them at runtime, either through code or by using Key Vault references in the
  application settings.

- Reducing Application Boot Time: The current configuration installs
  dependencies on startup. To reduce cold start times, bake the application's
  code and dependencies into a custom container image. This ensures the
  container is ready to serve requests immediately upon starting.
*/

resource "azurerm_linux_web_app" "main" {
  name                = "${var.resource_prefix}-app-service-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true

  # Use a system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Site configuration for the application
  site_config {
    always_on        = true
    app_command_line = var.flask_startup_command

    application_stack {
      docker_image_name        = var.docker_image_name
      docker_registry_username = var.docker_username
      docker_registry_password = var.docker_password
    }
  }

  # Environment variables
  app_settings              = var.app_environment_vars
  virtual_network_subnet_id = var.subnet_id

  lifecycle {
    ignore_changes = [
      # Allow CI/CD pipeline to change the container image without causing terraform drift
      site_config[0].application_stack[0].docker_image_name,
      app_settings["WEBSITES_ENABLE_APP_SERVICE_STORAGE"],
    ]
  }

  tags = var.tags
}
