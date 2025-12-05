# cSecBridge-AZ: API Service on Azure

Welcome to `cSecBridge-AZ`, a comprehensive project demonstrating the end-to-end deployment of a secure and scalable API service on Microsoft Azure. This repository showcases modern DevOps practices, including Infrastructure as Code (IaC) with Terraform and automated CI/CD pipelines using Azure DevOps.

The primary goal is to provide a reference architecture for building, deploying, and managing cloud-native applications on Azure.

## Project Structure
The repository is organized into distinct directories, each with a specific functionality:

```
csecbridge-az/
├── csb-api-iac/
│   └── terraform/      # Terraform code for Azure infrastructure
├── csb-api-service/
│   └── ...             # Source code for the API
├── csb-devops/
│   ├── build-scripts/    # Build container image and Automation scripts to setup Azure DevOps
│   ├── pipelines/        # Azure DevOps pipelines for CI/CD
│   └── build-container/  # Debain based container image pre-configured with build and deployment tools (Terraform, Azure CLI etc.)
└── README.md
```

-   **`csb-api-app/`**: Contains a simple Flask based API service, used as reference application for deployment.
-   **`csb-api-iac/`**: Holds the Infrastructure as Code (IaC) definitions, written in Terraform, to provision all necessary Azure resources.
-   **`csb-devops/`**: Contains all DevOps-related assets, including setup scripts and Azure DevOps pipeline definitions (`.yml`) for automating the CI/CD process.

## Core Components
### 1. Infrastructure as Code (`csb-api-iac`)

The entire Azure infrastructure is defined declaratively using **Terraform**. This includes:
-   **Networking**: Virtual Networks (for App and DevOps), Subnets, VNet Peering, and Private Endpoints.
-   **Databases**: An Azure Database for PostgreSQL Flexible Server and a Redis cache (running in Azure Container Instances).
-   **Compute**: An Azure App Service Plan and App Service for running the containerized API.

This approach ensures that the infrastructure is version-controlled, repeatable, and easy to manage.

### 2. DevOps Automation (`csb-devops`)
Automation is managed through **Azure DevOps** and **Docker**.

For detailed instructions on setting up and using the pipelines, please refer to the **csb-devops/README.md**.

## Technology Stack
-   For Application refer to **csb-api-app/README.md**
-   For Infrastructure as Code refer to **csb-api-iac/README.md**
-   For DevOps refer to **csb-devops/README.md**

## Getting Started
To get this project up and running, the necessary prerequisites must be set up and the CI/CD pipelines configured.

### Prerequisites
1.  **Azure Account**: An active Azure subscription.
2.  **Azure DevOps**: An organization and project in Azure DevOps.
3.  **Azure CLI**: Installed and configured on a local machine.
4.  **Terraform**: Installed on a local machine.
5.  **Docker**: Installed on a local machine.

### Setup and Deployment
The deployment process is fully automated. For a complete guide on configuring the service connections, variable groups, and running the pipelines, please follow the detailed instructions in the **docs/install.md** (Under Development) and **csb-devops/README.md**.

## Contribution
Contributions are welcome. For suggestions, improvements, or issues, please open an issue or submit a pull request.

## License
This project is licensed under the MIT License. See the `LICENSE` file for details.