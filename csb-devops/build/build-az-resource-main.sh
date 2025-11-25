#!/bin/bash
#
# -----------------------------------------------------------------------------
# Script     : build-az-resource-main.sh
# Description: This script bootstraps the core infrastructure required for
#              managing the application's state with Terraform. It ensures
#              the necessary Azure resources are in place before running
#              Terraform plans or applies.
#
#  1.  Performs initial checks for required tools and environment variables.
#  2.  Creates the primary DevOps resource group if it doesn't exist.
#  3.  Creates the Azure Storage Account for the Terraform backend if it
#      doesn't exist using a local Terraform apply. The storage account is
#      configured with network rules to restrict access.
#  4.  Assigns the 'Storage Blob Data Contributor' role to the Service
#      Principal, allowing the CI/CD pipeline to manage the state file.
#
# Pre-requisites:
#  1. Azure CLI (`az`) must be installed and you must be logged in.
#  2. The script sources variables from '_build-az-devops-vars.sh'.
#  3. The following environment variables must be set:
#   - AZ_DEVOPS_SP_ID: The Client ID (or Application ID) of the Service
#     Principal that will be used by Terraform to access the state file.
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status.
set -e

# Source the environment variables
source ./_build-az-devops-vars.sh

# Terraform directory
TERRAFORM_DIR="$(pwd)"

# Configuration
AZ_DEVOPS_RESOURCE_GROUP="csb-az-devops-rg"
AZ_MAIN_RESOURCE_GROUP="csb-main"
AZ_VNET_NAME="vnet-southeastasia"
AZ_SUBNET_NAME="snet-southeastasia-1"
AZ_STORAGE_ACCOUNT_NAME="csbinfrastatev1"
AZ_BLOB_CONTAINER_NAME="csb-infra-state-v1"
AZ_LOCATION="southeastasia"
AZ_STORAGE_ROLE_NAME="Storage Blob Data Contributor"

# Helper function to format log messages with timestamp
console_log() {
    DATE_FORMAT=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$DATE_FORMAT :: $1"
}

# Helper function to check the environment variables
check_env_var() {
    if [ -z "${!1}" ]; then
        console_log "Error: Environment variable '$1' is not set."
        exit 1
    fi
}

# Helper function to check for Microsoft.Storage service endpoint on a subnet
check_storage_service_endpoint() {
    console_log "Checking for 'Microsoft.Storage' service endpoint on subnet '${AZ_SUBNET_NAME}'..."
    local endpoints
    endpoints=$(az network vnet subnet show \
        --resource-group "${AZ_MAIN_RESOURCE_GROUP}" \
        --vnet-name "${AZ_VNET_NAME}" \
        --name "${AZ_SUBNET_NAME}" \
        --query "serviceEndpoints[?service=='Microsoft.Storage'].service" \
        --output tsv)

    if [ "$endpoints" != "Microsoft.Storage" ]; then
        console_log "Error: 'Microsoft.Storage' service endpoint is not enabled on subnet '${AZ_SUBNET_NAME}'."
        console_log "Please enable it before configuring network settings on Storage account."
        exit 1
    fi
    console_log "Service endpoint check passed."
}

console_log "Performing initial checks..."

# Check for required environment variables
check_env_var "AZ_DEVOPS_SP_ID"

# Check for required tools
if ! command -v az &> /dev/null; then
    console_log "Error: 'az' (Azure CLI) is required. Please install it."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    console_log "Error: 'terraform' is required. Please install it."
    exit 1
fi

console_log "Initial checks completed."

# 1. Create Resource Group if it doesn't exist
console_log "Checking for resource group '${AZ_DEVOPS_RESOURCE_GROUP}'..."
if ! az group exists --name "${AZ_DEVOPS_RESOURCE_GROUP}" --output none; then
  console_log "Resource group not found. Creating '${AZ_DEVOPS_RESOURCE_GROUP}' in '${AZ_LOCATION}'..."
  az group create --name "${AZ_DEVOPS_RESOURCE_GROUP}" --location "${AZ_LOCATION}" > /dev/null
  console_log "Resource group created successfully."
else
  console_log "Resource group already exists."
fi

# Check if VNet exists
console_log "Checking for virtual network '${AZ_VNET_NAME}'..."
if ! az network vnet show --resource-group "${AZ_MAIN_RESOURCE_GROUP}" --name "${AZ_VNET_NAME}" &> /dev/null; then
    console_log "Error: Virtual network '${AZ_VNET_NAME}' not found in resource group '${AZ_MAIN_RESOURCE_GROUP}'."
    exit 1
fi

# Check if Subnet exists
console_log "Checking for subnet '${AZ_SUBNET_NAME}'..."
if ! az network vnet subnet show --resource-group "${AZ_MAIN_RESOURCE_GROUP}" --vnet-name "${AZ_VNET_NAME}" --name "${AZ_SUBNET_NAME}" &> /dev/null; then
    console_log "Error: Subnet '${AZ_SUBNET_NAME}' not found in virtual network '${AZ_VNET_NAME}'."
    exit 1
else
    console_log "VNet and Subnet checks passed."
fi

# 2. Check subnet service endpoint
check_storage_service_endpoint

# 3. Run Terraform to create the storage account
console_log "Running Terraform to provision the DevOps storage account..."
cd "${TERRAFORM_DIR}"

console_log "Initializing Terraform..."
terraform init -reconfigure > /dev/null

console_log "Applying Terraform configuration..."

console_log "Querying for subnet ID..."
AZ_DEVOPS_SUBNET_ID=$(az network vnet subnet show \
    --resource-group "${AZ_MAIN_RESOURCE_GROUP}" \
    --vnet-name "${AZ_VNET_NAME}" \
    --name "${AZ_SUBNET_NAME}" --query id -o tsv)

terraform apply -auto-approve -var="allowed_subnet_id=${AZ_DEVOPS_SUBNET_ID}" > /dev/null

console_log "Terraform apply completed."

# 4. Create Role Assignment for the Service Principal
console_log "Assigning role '${AZ_STORAGE_ROLE_NAME}' to Service Principal '${AZ_DEVOPS_SP_ID}'..."
az role assignment create \
  --assignee "${AZ_DEVOPS_SP_ID}" \
  --role "${AZ_STORAGE_ROLE_NAME}" \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${AZ_DEVOPS_RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/${AZ_STORAGE_ACCOUNT_NAME}"

console_log "Role assignment complete."
console_log "Bootstrap script finished successfully."