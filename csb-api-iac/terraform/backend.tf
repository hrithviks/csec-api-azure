/*
Project     : CSB-API-Service Infrastructure Configuration
Module      : Root Configuration
Description : Root configuration for CSB-API-Service
Context     : Backend Configuration
*/

/*
NOTE: This backend configuration uses Azure Blob Storage for simplicity and is
suitable for a demonstration. For an enterprise grade solution, consider the
following enhancements to secure the state file and improve resiliency.

1.  Securing the State File: The Terraform state file can contain sensitive
    data. To protect it:
    - Enable State Locking: This configuration correctly uses the `azurerm`
      backend, which natively supports state locking to prevent concurrent
      runs from corrupting the state. This is a critical feature.

    - Restrict Access: Use Azure RBAC to limit access to the storage
      account. Only authorized administrators and the CI/CD pipeline's service
      principal should have `Storage Blob Data Contributor` rights.

    - Use Private Networking: For maximum security, configure the storage
      account's firewall to deny public access and create a private endpoint,
      making the state file accessible only from within virtual network.

2.  Improving Redundancy: To protect against data loss or corruption:
    - Geo-Redundant Storage (GRS): The storage account hosting the state
      file should be configured with at least Geo-Redundant Storage (GRS) to
      protect against a regional outage.

    - Enable Blob Versioning: Enable blob versioning on the storage account.
      This keeps previous versions of state file, allowing you to
      recover from accidental deletion or corruption.
*/

terraform {
  backend "azurerm" {
    resource_group_name  = "csec-az-devops-rg"
    storage_account_name = "csecinfracontainer"
    container_name       = "csec-infra-state-v1"
    key                  = "build.tfstate"
  }
}
