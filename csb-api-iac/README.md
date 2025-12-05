# cSecBridge API-Service - Infrastructure

This repository contains the Infrastructure as Code (IaC) for the **CSB-API-Service**, managed with [Terraform](https://www.terraform.io/) and deployed on Microsoft Azure.

The infrastructure is designed to be secure, scalable, and modular, providing a robust environment for the Python Flask application.

## Architecture Overview

The deployed architecture consists of the following core components:

-   **Azure App Service**: A Linux-based App Service Plan hosts the Python application, integrated directly into a private virtual network.
-   **Azure Database for PostgreSQL**: A Flexible Server instance for the primary relational database, secured within the VNet using a Private Endpoint.
-   **Azure Container Instances**: A private Redis container provides a fast in-memory cache, accessible only from within the virtual network.
-   **Azure Networking**: A Virtual Network (VNet) with multiple subnets isolates application and database resources. Network Security Groups (NSGs) are used to enforce strict traffic rules between subnets and the internet.

All backend services are designed to be inaccessible from the public internet, communicating exclusively over private network channels.

### DevOps Connectivity

A key feature of this architecture is the secure connectivity between the Azure DevOps environment and the application infrastructure. This is achieved through:

-   **VNet Peering**: The application's VNet is peered with a dedicated DevOps VNet, which hosts the self-hosted CI/CD agent.
-   **Private DNS Integration**: The DevOps VNet is linked to the application's private DNS zone for PostgreSQL, allowing the agent to resolve the database's private IP address.
-   **Network Security Group (NSG) Rules**: A specific NSG rule is dynamically added to allow inbound traffic on port `5432` from the DevOps agent's subnet to the database's private endpoint.

### Database Initialization

Provisioning the infrastructure with Terraform creates an empty PostgreSQL database. A subsequent, automated step in the Azure DevOps pipeline is responsible for bootstrapping the database schema.

This is accomplished by executing the `postgres/init.sql` script against the newly created database. This script is **idempotent**, meaning it is written with checks (e.g., `CREATE TABLE IF NOT EXISTS`) to ensure it can be run multiple times without causing errors or unintended side effects.

This initialization is performed by the self-hosted DevOps agent, leveraging the secure VNet peering to connect to the private database and apply the initial schema.

## Directory Structure

```
.
└── terraform/
    ├── modules/
    │   ├── app-service/
    │   ├── databases/
    │   ├── network/
    │   └── security/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── csb_dev.tfvars
```

-   `terraform/`: The root directory for all Terraform configuration.
-   `terraform/modules/`: Contains the reusable Terraform modules for each logical part of the infrastructure.

## Getting Started

### Prerequisites

-   Terraform CLI (v1.0.0+)
-   Azure CLI

### Deployment Steps

1.  **Authenticate with Azure**:
    ```sh
    az login
    ```

2.  **Navigate to the Terraform directory**:
    ```sh
    cd terraform
    ```

3.  **Initialize Terraform**:
    This will download the necessary providers and initialize the backend.
    ```sh
    terraform init
    ```

4.  **Review the Execution Plan**:
    Use the provided `.tfvars` file to see what resources will be created.
    ```sh
    terraform plan -var-file="csb_dev.tfvars"
    ```

5.  **Apply the Configuration**:
    This command will provision all the Azure resources.
    ```sh
    terraform apply -var-file="csb_dev.tfvars"
    ```