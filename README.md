# cSecBridge-AZ: API Service on Azure

Welcome to `cSecBridge-AZ`, a comprehensive project demonstrating the end-to-end deployment of a secure and scalable API service on Microsoft Azure. This repository showcases modern DevOps practices, including Infrastructure as Code (IaC) with Terraform and automated CI/CD pipelines using Azure DevOps.

The primary goal is to provide a reference architecture for building, deploying, and managing cloud-native applications on Azure.

## Project Structure

The repository is organized into distinct directories, each with a specific responsibility:

```
csecbridge-az/
├── csb-api-iac/
│   └── terraform/      # Terraform code for Azure infrastructure
├── csb-api-service/
│   └── ...             # Source code for the API
├── csb-devops/
│   ├── build/          # Automation scripts to build Azure DevOps components
│   ├── pipelines/ 
│   └── ubuntu/         # Ubuntu based container image pre-configured with Terraform and Azure CLI
└── README.md
```

-   **`csb-api-service/`**: Contains the source code for the backend API. *(Note: This is a logical placeholder for your application code.)*
-   **`csb-api-iac/`**: Holds the Infrastructure as Code (IaC) definitions, written in Terraform, to provision all necessary Azure resources.
-   **`csb-devops/`**: Contains all DevOps-related assets, including Dockerfiles for containerizing the application and Azure DevOps pipeline definitions (`.yml`) for automating the CI/CD process.

## Core Components

### 1. Infrastructure as Code (`csb-api-iac`)

The entire Azure infrastructure is defined declaratively using **Terraform**. This includes:
-   **Networking**: Virtual Network, Subnets, and Network Security Groups.
-   **Databases**: An Azure Database for PostgreSQL Flexible Server and a Redis cache running in an Azure Container Instance.
-   **Compute**: Resources for running the containerized API service.

This approach ensures that the infrastructure is version-controlled, repeatable, and easy to manage.

### 2. DevOps Automation (`csb-devops`)

Automation is managed through **Azure DevOps Pipelines** and **Docker**.

-   **Containerization**: The API service and its Redis dependency are containerized using Dockerfiles located in `csb-devops/build/`. This ensures consistency across development, testing, and production environments.
-   **Continuous Integration (CI)**: A CI pipeline can be configured to automatically build and push the application's Docker image to a container registry (e.g., Azure Container Registry or GitHub Container Registry) upon code changes.
-   **Continuous Deployment (CD)**: The `terraform.yml` template in `csb-devops/pipelines/templates/` automates the deployment of the Terraform-defined infrastructure. A main pipeline orchestrates the deployment across different environments (e.g., dev, prod).

For detailed instructions on setting up and using the pipelines, please refer to the **csb-devops/README.md**.

## Technology Stack

-   **Cloud Provider**: Microsoft Azure
-   **Infrastructure as Code**: Terraform
-   **CI/CD**: Azure DevOps Pipelines
-   **Containerization**: Docker
-   **Databases**: Azure Database for PostgreSQL, Redis

## Getting Started

To get this project up and running, you will need to set up the necessary prerequisites and configure the CI/CD pipelines.

### Prerequisites

1.  **Azure Account**: An active Azure subscription.
2.  **Azure DevOps**: An organization and project in Azure DevOps.
3.  **Azure CLI**: Installed and configured on your local machine.
4.  **Terraform**: Installed on your local machine.

### Setup and Deployment

The deployment process is fully automated. For a complete guide on configuring the service connections, variable groups, and running the pipelines, please follow the detailed instructions in the **csb-devops/README.md**.

## Contribution

Contributions are welcome! If you have suggestions for improvements or find any issues, please feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.