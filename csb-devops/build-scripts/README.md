# cSecBridge-AZ DevOps

This repository contains the Continuous Integration and Continuous Deployment (CI/CD) pipeline definitions for the `cSecBridge-AZ` project, managed with Azure DevOps.

## Overview

The primary goal of this DevOps setup is to automate the provisioning and management of the Azure infrastructure required for the CSB-API-Service. It leverages Azure DevOps Pipelines and Terraform to create a repeatable and reliable deployment process.

## Directory Structure

```
csb-devops/
├── pipelines/
│   ├── templates/
│   │   └── terraform.yml   # Reusable template for Terraform deployments
│   └── azure-pipelines.yml # Example main pipeline definition
└── README.md
```
- **`build/`**: Contains Dockerfiles for building container images used in the project.

---

## Pipeline Templates

### Docker Image Builds

The `build/docker/` directory contains the `Dockerfile` definitions for the services that make up the `cSecBridge-AZ` application.

#### **`csb-api/Dockerfile`**

This Dockerfile is responsible for building the container image for the main `CSB-API-Service`. A CI pipeline should be configured to:
1.  Build a Docker image using this file.
2.  Tag the image appropriately (e.g., with the build ID or a semantic version).
3.  Push the image to a container registry (like Azure Container Registry or GitHub Container Registry).

#### **`redis/Dockerfile`**

This Dockerfile builds a custom Redis image. The Terraform configuration (`modules/databases/main.tf`) deploys this image to an Azure Container Instance. It's designed to initialize Redis with specific users and credentials required by the API service.

### Terraform Deployment (`terraform.yml`)

This is a generic and reusable Azure DevOps pipeline template designed to deploy infrastructure using Terraform. It standardizes the `init`, `plan`, and `apply` workflow for any given Terraform configuration.

#### **Purpose**

To provide a consistent and automated process for deploying Terraform-managed infrastructure across different environments (e.g., Development, Testing, Production).

#### **Parameters**

The template is parameterized to make it flexible for various use cases.

| Parameter                  | Type   | Description                                                                          | Example Value                 |
| -------------------------- | ------ | ------------------------------------------------------------------------------------ | ----------------------------- |
| `environmentName`          | string | A short name for the target environment.                                             | `Dev`                         |
| `environmentDisplayName`   | string | The full display name for the environment.                                           | `Development`                 |
| `tfVarFile`                | string | The name of the Terraform variables file (`.tfvars`) to use for the deployment.      | `csb_dev.tfvars`              |
| `tfStateFileKey`           | string | The key (filename) for the Terraform state file in the Azure Blob Storage container. | `dev.terraform.tfstate`       |
| `azureServiceConnection`   | string | The name of the Azure DevOps service connection to authenticate with Azure.          | `azure-dev-connection`        |
| `terraformWorkingDirectory`| string | The path to the directory containing the Terraform configuration files (`.tf`).      | `csb-api-iac/terraform`       |

#### **Workflow**

The template performs the following steps in a single `AzureCLI` task for efficiency:

1.  **Authenticate**: Sets up environment variables (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, etc.) for Terraform to authenticate with Azure using the provided service connection.
2.  **Terraform Init**: Initializes the Terraform backend, configuring it to use the specified state file in Azure Blob Storage. The `-reconfigure` flag ensures the backend is cleanly re-initialized on every run.
3.  **Terraform Plan**: Creates an execution plan and saves it to a file (`tfplan`). This step uses the specified `.tfvars` file to populate input variables.
4.  **Terraform Apply**: Applies the generated plan to create or update the infrastructure in Azure. The `-auto-approve` flag allows the pipeline to run without manual intervention.

---

## Prerequisites

Before running the pipelines, the following must be configured:

1.  **Azure DevOps Project**: An Azure DevOps project to host the repository and pipelines.
2.  **Azure Subscription**: An active Azure subscription where the resources will be deployed.
3.  **Terraform State Storage**: An Azure Storage Account and a Blob Container to store the Terraform state files remotely and securely. The details of this storage account are used in the `backend.tf` file of the Terraform configuration.
4.  **Service Connection**: An Azure DevOps service connection with sufficient permissions (`Contributor` role on the target subscription is typical) to manage resources in the Azure subscription.
5.  **Variable Groups**: For managing secrets and environment-specific variables, create Variable Groups in Azure DevOps under **Pipelines > Library**. The `terraform.yml` template expects secrets like `TF_VAR_csec_api_auth_token` to be available as environment variables.

## How to Use

1.  **Create a Pipeline**: In the Azure DevOps project, create a new pipeline and point it to the main pipeline definition file (e.g., `pipelines/azure-pipelines.yml`) in this repository.

2.  **Define Stages**: In the main pipeline file, define stages for each environment to deploy to (e.g., Dev, Prod).

3.  **Call the Template**: Within each stage, call the `terraform.yml` template and provide the appropriate parameters for that environment.

    **Example `azure-pipelines.yml`:**

    ```yaml
    # azure-pipelines.yml
    trigger:
    - main

    pool:
      vmImage: 'ubuntu-latest'

    stages:
    - stage: DeployDev
      displayName: 'Deploy to Development'
      jobs:
      - job: TerraformDeploy
        displayName: 'Terraform Deploy'
        steps:
        - template: templates/terraform.yml
          parameters:
            environmentName: 'Dev'
            environmentDisplayName: 'Development'
            tfVarFile: 'csb_dev.tfvars'
            tfStateFileKey: 'dev.terraform.tfstate'
            azureServiceConnection: 'your-azure-service-connection'
            terraformWorkingDirectory: '$(System.DefaultWorkingDirectory)/csb-api-iac/terraform'
    ```