# **Project Plan: cSecBridge API-Service Deployment to Azure WebApp**

**Goal:** To deploy an existing Flask application to a secure Azure App Service environment (using private PaaS) via a complete CI/CD workflow, with infrastructure provisioned by Terraform.

| Phase | Task | Est. Duration (Hours) | Key Deliverable / Outcome |
| :---- | :---- | :---- | :---- |
| **1\. Setup & Identity** | Create Azure DevOps Project & Git Repos (one for IaC, one for Flask app). | 0.5 | Two empty, initialized Git repositories. |
|  | Create Service Principal (SPN) for Terraform with Contributor rights. | 0.5 | Application (client) ID, Client Secret, and Tenant ID. |
|  | Create Azure DevOps Service Connection for Terraform (using SPN). | 0.5 | A secure, named Service Connection (sc-terraform-deploy). |
|  | **(Subtotal)** |  | **(1.5 Hours)** |
| **2\. Infrastructure (Terraform)** | Configure Terraform backend (Azure Storage for state file). | 1.0 | A storage container for terraform.tfstate. |
|  | Define core network (VNet, 2x Subnets, Private DNS Zones). | 2.0 | network.tf file. |
|  | Define PaaS databases (Postgres & Redis, public access disabled). | 1.5 | databases.tf file. |
|  | Define App Service (Plan, App Service, VNet Integration). | 1.5 | appservice.tf file. |
|  | Define security (Private Endpoints for DBs, DNS records). | 2.0 | private\_endpoints.tf file. |
|  | Define pipeline for Terraform (azure-pipelines-iac.yml) to run plan & apply. | 2.0 | A working IaC pipeline that builds the environment. |
|  | **(Subtotal)** |  | **(10.0 Hours)** |
| **3\. CI/CD (App Deployment)** | Push Flask app code (with requirements.txt & gunicorn) to its repo. | 0.5 | Flask app code is in Azure Repos. |
|  | Define App CI/CD pipeline (azure-pipelines-app.yml) \- Build Stage. | 1.5 | CI stage that creates a .zip artifact (e.g., drop). |
|  | Define App CI/CD pipeline (azure-pipelines-app.yml) \- Deploy Stage. | 1.0 | AzureWebApp@1 task that deploys the drop to App Service. |
|  | Pass DB credentials to App Service (use Terraform azurerm\_app\_service\_configuration). | 1.0 | App Service has its environment variables set securely. |
|  | **(Subtotal)** |  | **(4.0 Hours)** |
| **4\. Validation** | Run the full end-to-end deployment (push a code change to Flask app). | 1.0 | Successful, automated deployment from code to cloud. |
|  | Test the deployed application and confirm database connectivity. | 1.0 | A working application, validating the entire architecture. |
|  | Practice demo workflow: terraform destroy and terraform apply. | 0.5 | Confidence in the spin-up/teardown process. |
|  | **(Subtotal)** |  | **(2.5 Hours)** |
|  | **Total Estimated Effort** |  | **\~18 Hours** |

