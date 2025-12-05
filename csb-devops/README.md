# cSecBridge-AZ: DevOps Automation

Welcome to the `csb-devops`. This section contains all the assets required to establish a robust, automated CI/CD workflow for the `cSecBridge-AZ` project using Azure DevOps. The primary goal is to securely and reliably deliver the application to end-users by automating the entire lifecycle, from infrastructure provisioning to application deployment.

## Overview

This directory contains the automation assets for a **mono-repo** structure, designed to support multiple, independent CI/CD workflows for different components of the project. The strategy is built on two core components:

1.  **Bootstrapping Scripts**: A collection of idempotent shell scripts to perform the one-time setup of the Azure DevOps environment, including creating service connections and agent pools.
2.  **CI/CD Pipelines**: A set of distinct Azure DevOps pipelines for different concerns:
    -   **Infrastructure Pipeline (`az-csec-infra.yml`)**: Validates and deploys the Terraform infrastructure and performs post-deployment configuration. This pipeline is triggered by changes in the `csb-api-iac` directory.
    -   **Application Pipeline (Conceptual)**: A separate pipeline would be responsible for building, testing, and pushing the container image for the `csb-api-app`. This pipeline would be triggered by changes in the `csb-api-app` directory.
    -   **Application Pipeline (`az-csec-app.yml`)**: A CI/CD pipeline that validates, builds, scans, and deploys the containerized Flask application. This pipeline is triggered by changes in the `csb-api-app` directory.

## Directory Structure

```
csb-devops/
├── build-scripts/      # Scripts for bootstrapping the DevOps environment
├── pipelines/
│   ├── templates/      # Reusable pipeline templates (e.g., for Terraform, DB deployment)
│   └── az-csec-infra.yml # The main infrastructure CI/CD pipeline
└── README.md
```

-   **`build-scripts/`**: Contains shell scripts to automate the setup of Azure and Azure DevOps prerequisites. These are designed to be run once to prepare the environment for the CI/CD pipelines.
-   **`pipelines/`**: Contains the YAML definitions for the Azure DevOps pipelines. It includes a main pipeline and reusable templates that encapsulate common deployment logic.

---

## Getting Started: DevOps Environment Setup

Before the main CI/CD pipeline can be run, the Azure and Azure DevOps environments must be bootstrapped. The scripts in the `build-scripts` directory automate this process. They are designed to be run sequentially from a local machine.

### Prerequisites

1.  **Azure CLI**: An active login session is required (`az login`).
2.  **Service Principal**: A Service Principal with `Contributor` rights on the target Azure subscription.
3.  **Azure DevOps PAT**: A Personal Access Token with permissions to manage Agent Pools and Service Connections.
4.  **Configuration File**: All scripts source their variables from `_build-az-devops-vars.sh`. The template must be copied and populated with project-specific values.

### Execution Sequence

Execute the scripts in the following order from the `build-scripts` directory:

**1. `01-build-az-devops-base.sh`**

   -   **Purpose**: Provisions the foundational Azure resources required for the DevOps process itself.
   -   **Actions**:
       -   Creates a dedicated resource group for DevOps assets.
       -   Creates a storage account to hold the Terraform remote state (`.tfstate`) files.
       -   Configures network rules on the storage account to restrict access.
       -   Assigns the `Storage Blob Data Contributor` role to the Service Principal, allowing it to manage state files.

**2. `02-build-az-devops-network.sh`**

   -   **Purpose**: Sets up the private network for the self-hosted DevOps agent.
   -   **Actions**:
       -   Creates a Virtual Network (VNet) and a subnet where the agent VM will reside. This VNet will later be peered with the application's VNet.

**3. `03-build-az-devops-setup.sh`**

   -   **Purpose**: Configures the Azure DevOps project with the necessary connections and pools.
   -   **Actions**:
       -   Creates an **Agent Pool** for the self-hosted agents.
       -   Creates an **Azure Resource Manager (ARM) Service Connection** using the Service Principal, allowing the pipeline to authenticate with Azure.
       -   Creates a **Docker Registry Service Connection** for GitHub Container Registry (GHCR), allowing the pipeline to pull container images.

**4. `04-build-az-devops-agent.sh`**

   -   **Purpose**: Provisions and configures a Linux VM to act as a self-hosted agent.
   -   **Actions**:
       -   Deploys an Azure VM into the DevOps VNet created in step 2.
       -   Uses a cloud-init script to install necessary tools (Docker, Terraform, Azure CLI, etc.).
       -   Downloads the Azure DevOps agent, registers it with the agent pool created in step 3, and configures it to run as a service.

**5. `05-build-az-devops-pipelines.sh` (Placeholder)**

   -   **Purpose**: Creates the Azure DevOps pipelines from the YAML definitions in the repository.
   -   **Actions**:
       -   Uses the Azure DevOps CLI (`az pipelines create`) to register `az-csec-infra.yml` as a pipeline in the project.
       -   (Conceptual) This script would also register other pipelines, such as the application CI pipeline, once they are defined.

After completing these steps, the Azure DevOps project will be fully configured with all necessary pipelines, ready for execution.

---

## CI/CD Pipeline: `az-csec-infra.yml`

This is the main pipeline responsible for the end-to-end deployment of the application infrastructure. It is designed with a multi-stage approach to ensure quality, security, and a clear promotion path from development to production.

### Pipeline Stages

**1. `Validate` Stage**

   -   **Purpose**: Performs static analysis on the Terraform code before any deployment. This acts as a quality and security gate.
   -   **Jobs**:
       -   **Code Quality**: Runs `terraform fmt` to check formatting and `tflint` to identify potential errors and enforce best practices.
       -   **Security Scan**: Uses `tfsec` to perform Static Application Security Testing (SAST) on the IaC, detecting security misconfigurations.

**2. `Deploy_Dev` Stage**

   -   **Purpose**: Deploys the infrastructure to the **Development** environment.
   -   **Logic**: This stage calls the reusable `templates/terraform.yml` template, providing it with development-specific parameters (e.g., variable files, state file key). It targets an Azure DevOps Environment named `csec-dev` for deployment tracking.

**3. `Configure_Dev` Stage**

   -   **Purpose**: Performs post-deployment configuration on the newly created infrastructure. This stage runs only after `Deploy_Dev` succeeds.
   -   **Jobs**:
       -   **Initialize Database Schema**: Connects to the private PostgreSQL database (leveraging VNet peering) and executes the idempotent `init.sql` script to create the necessary tables and users.
       -   **Set Database Passwords**: Securely retrieves randomly generated user passwords from Azure Key Vault and runs `ALTER USER` commands to set them in the database. This separates schema creation from credential management.

**4. `Deploy_Test` & `Deploy_Prod` Stages**

   -   **Purpose**: Placeholder stages for deploying to **Test** and **Production** environments.
   -   **Status**: These stages are disabled by default (`condition: false`). In a real-world scenario, they would be enabled and configured with manual approval gates in the Azure DevOps UI to provide a control point before deploying to critical environments.

### Reusable Templates

The pipeline heavily utilizes templates to promote Don't-Repeat-Yourself (DRY) principles.

-   **`pipelines/templates/terraform.yml`**: A generic template that encapsulates the `terraform init`, `plan`, and `apply` workflow. It is parameterized to work with any environment.
-   **`pipelines/templates/db-deploy.yml`**: A template designed to run scripts against the PostgreSQL database. It handles the logic for securely connecting to the database using credentials from Key Vault.

---

## CI/CD Pipeline: `az-csec-app.yml`

This pipeline automates the Continuous Integration (CI) and Continuous Deployment (CD) for the `csb-api-app`. It follows a "shift-left" security model by integrating quality and security checks early in the development process.

### Pipeline Stages

**1. `Build` Stage (Continuous Integration)**

   -   **Purpose**: To validate the application code and produce a secure, production-ready container image artifact. This stage acts as a comprehensive quality gate.
   -   **Jobs & Key Steps**:
       -   **SAST Scan**: Runs `Bandit` to perform Static Application Security Testing on the Python source code, identifying common security vulnerabilities.
       -   **Dependency Scanning**: Uses `Trivy` to scan the `requirements.txt` file for known CVEs in the project's dependencies.
       -   **Linting**: Runs `Flake8` to enforce code style and quality standards, ensuring readability and maintainability.
       -   **Build Docker Image**: Builds the application's container image using the `Dockerfile`.
       -   **Container Image Scanning**: Uses `Trivy` again to scan the newly built Docker image for vulnerabilities in the base OS and system packages.
       -   **Push to Registry**: If all checks pass, the validated image is tagged and pushed to GitHub Container Registry (GHCR).

**2. `Deploy_Dev` Stage (Continuous Deployment)**

   -   **Purpose**: Deploys the new application version to the **Development** environment and validates its health.
   -   **Jobs & Key Steps**:
       -   **Deploy Database Schema**: Connects to the Dev database and applies any necessary schema changes or migrations from the `backend.sql` script.
       -   **Configure App Service**: Updates the Azure App Service application settings, securely fetching secrets (like the database password) from Azure Key Vault at runtime.
       -   **Deploy Application**: Deploys the new container image from GHCR to the Azure App Service instance.
       -   **Post-Deployment Validation**: Runs automated integration or health check tests against the live application endpoint to ensure the deployment was successful and the service is operational.

**3. `Deploy_Test` Stage**

   -   **Purpose**: A placeholder stage for promoting the application to a **Test** environment for more rigorous QA or UAT.
   -   **Status**: This stage is disabled by default (`condition: false`) but mirrors the Dev deployment process, demonstrating a consistent promotion model across environments.
