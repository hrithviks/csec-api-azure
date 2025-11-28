#!/bin/bash
#
# -----------------------------------------------------------------------------
# Script      : build-az-devops-base.sh
# Description : This script bootstraps the core infrastructure required for
#               managing the application's state with Terraform. It ensures
#               the necessary Azure resources are in place before running
#               Terraform plans or applies.
#
#  1.  Performs initial checks for required tools and environment variables.
#  2.  Runs a local Terraform apply to create the DevOps resource group,
#      VNet, Subnet, and the Azure Storage Account for the Terraform backend.
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
set -o pipefail
set -u

# Source the environment variables
source ./_build-az-devops-vars.sh

# Terraform directory
TERRAFORM_DIR="$(pwd)"

# Configuration
AZ_DEVOPS_RESOURCE_GROUP="csec-az-devops-rg"
AZ_STORAGE_ACCOUNT_NAME="csecinfracontainer"
AZ_LOCATION="southeastasia"
AZ_STORAGE_ROLE_NAME="Storage Blob Data Contributor"
AZ_DEVOPS_VNET="csec-az-devops-vnet"
AZ_DEVOPS_SUBNET="csec-az-devops-snet"

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

console_log "Performing initial checks..."

# Check for required environment variables
check_env_var "AZ_DEVOPS_SP_ID"

# Export environment variables for the Terraform azurerm provider.
# This allows Terraform to authenticate using the service principal credentials.
export ARM_CLIENT_ID="${AZ_DEVOPS_SP_ID}"
export ARM_CLIENT_SECRET="${AZ_DEVOPS_CLIENT_SECRET}"
export ARM_SUBSCRIPTION_ID="${AZ_DEVOPS_SUBSCR_ID}"
export ARM_TENANT_ID="${AZ_DEVOPS_TENANT_ID}"

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

# Log in to Azure CLI using the Service Principal
console_log "Logging into Azure with Service Principal..."
az login --service-principal \
  -u "${AZ_DEVOPS_SP_ID}" \
  -p "${AZ_DEVOPS_CLIENT_SECRET}" \
  --tenant "${AZ_DEVOPS_TENANT_ID}" > /dev/null

# Run Terraform to provision the DevOps resources.
console_log "Running Terraform to provision DevOps resources..."
cd "${TERRAFORM_DIR}"

console_log "Initializing Terraform..."
terraform init -reconfigure -upgrade > /dev/null

console_log "Fetching Object ID for Service Principal '${AZ_DEVOPS_SP_ID}'..."
AZ_DEVOPS_SP_OBJECT_ID=$(az ad sp show --id "${AZ_DEVOPS_SP_ID}" --query "id" -o tsv)
if [ -z "$AZ_DEVOPS_SP_OBJECT_ID" ]; then
    console_log "Error: Could not find Object ID for Service Principal with Client ID '${AZ_DEVOPS_SP_ID}'."
    exit 1
fi
console_log "Service Principal Object ID found: ${AZ_DEVOPS_SP_OBJECT_ID}"
console_log "Running Terraform plan..."
terraform plan \
 -var="service_principal_object_id=${AZ_DEVOPS_SP_OBJECT_ID}" \
 -var="storage_account_name=${AZ_STORAGE_ACCOUNT_NAME}" \
 -var="resource_group_name=${AZ_DEVOPS_RESOURCE_GROUP}" \
 -var="location=${AZ_LOCATION}" \
 -var="storage_role_name=${AZ_STORAGE_ROLE_NAME}" \
 -var="vnet_name=${AZ_DEVOPS_VNET}" \
 -var="snet_name=${AZ_DEVOPS_SUBNET}"

console_log "Applying Terraform configuration..."
terraform apply -auto-approve \
 -var="service_principal_object_id=${AZ_DEVOPS_SP_OBJECT_ID}" \
 -var="storage_account_name=${AZ_STORAGE_ACCOUNT_NAME}" \
 -var="resource_group_name=${AZ_DEVOPS_RESOURCE_GROUP}" \
 -var="location=${AZ_LOCATION}" \
 -var="storage_role_name=${AZ_STORAGE_ROLE_NAME}" \
 -var="vnet_name=${AZ_DEVOPS_VNET}" \
 -var="snet_name=${AZ_DEVOPS_SUBNET}"

console_log "Terraform apply completed."
console_log "Bootstrap script finished successfully."