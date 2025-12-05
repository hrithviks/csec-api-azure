# Terraform Configuration for CSB-API-Service

This directory contains the complete Terraform configuration for deploying the `CSB-API-Service` infrastructure on Azure. The configuration is designed to be modular, reusable, and secure.

## Architecture

The Terraform code provisions the following architecture:

-   **Networking**:
    -   A Virtual Network (VNet) with a `/16` address space.
    -   Two primary subnets:
        -   `app-service-subnet`: For hosting the Azure App Service.
        -   `private-service-subnet`: For hosting backend services like the Redis container and Private Endpoints.
    -   Network Security Groups (NSGs) attached to each subnet with rules to allow traffic between the App Service and backend services on specific ports (PostgreSQL: 5432, Redis: 6379) and to allow inbound HTTPS traffic to the App Service.
    -   A Private DNS Zone for PostgreSQL to enable name resolution over the private network.

-   **Application Tier**:
    -   An Azure App Service Plan (Linux).
    -   An Azure App Service configured for Python, integrated with the `app-service-subnet`.
    -   A system-assigned Managed Identity for the App Service.
    -   A dedicated Storage Account for App Service logging.

-   **Data Tier**:
    -   **PostgreSQL**: An `azurerm_postgresql_flexible_server` instance with public access disabled. It is accessed via a Private Endpoint in the `private-service-subnet`.
    -   **Redis**: An `azurerm_container_group` running the official Redis image. It is deployed directly into the `private-service-subnet` and has no public IP address.

-   **Security**:
    -   An `azurerm_private_endpoint` for the PostgreSQL server.
    -   Randomly generated, secure passwords for both PostgreSQL and Redis.
    -   Secrets and connection details are passed to the App Service as secure environment variables.

## Modules

The infrastructure is broken down into the following logical modules:

-   `network`: Creates the VNet, subnets, NSGs, and Private DNS Zones.
-   `databases`: Provisions the PostgreSQL server and the Redis container instance.
-   `app-service`: Deploys the App Service Plan, the App Service itself, and its associated storage account.
-   `security`: Manages the Private Endpoint for the PostgreSQL server.

## Configuration and Variables

All environment-specific configuration is managed via `.tfvars` files. The `csb_dev.tfvars` file provides a working example for a development environment.

### Key Variables

-   `app_resource_group_name`: The name of the resource group.
-   `app_location`: The Azure region for deployment.
-   `vnet_subnets_map`: A map defining the subnets to be created.
-   `vnet_network_security_group_rules`: A map defining the NSG rules.
-   `csec_api_auth_token`: A sensitive variable for the application's API token.

> **Note on Secrets**: For a production environment, it is strongly recommended to manage secrets like `csec_api_auth_token` and database credentials using Azure Key Vault instead of passing them as variables.

## Deployment

1.  **Initialize Terraform**:
    ```sh
    terraform init
    ```

2.  **Validate Configuration**:
    Check for syntax errors in the configuration.
    ```sh
    terraform validate
    ```

3.  **Plan Deployment**:
    Review the resources that will be created.
    ```sh
    terraform plan -var-file="csb_dev.tfvars"
    ```

4.  **Apply Deployment**:
    Execute the plan to build the infrastructure.
    ```sh
    terraform apply -var-file="csb_dev.tfvars"
    ```