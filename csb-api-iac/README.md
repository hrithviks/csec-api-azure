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