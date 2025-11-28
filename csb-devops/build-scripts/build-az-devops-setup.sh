#!/bin/bash
#
# -----------------------------------------------------------------------------
# Script      : build-az-devops-setup.sh
# Description : This script automates the initial setup of an Azure DevOps
#               pipeline. It performs the following actions:
#
#  1. Creates a new organization-level agent pool for self-hosted agents.
#  2. Creates an Azure Resource Manager (ARM) service connection using a
#     manually-provided service principal.
#  3. Creates a Github Container Registry (GHCR) service connection.
#
# Pre-requisites:
#  1. Azure CLI (`az`) must be installed.
#  2. The Azure DevOps extension must be installed 
#   (`az extension add --name azure-devops`).
#  3. The script sources variables from '_build-az-devops-vars.sh'.
#  4. The following environment variables must be set in the sourced file or
#     execution shell
#
# For Azure DevOps Authentication:
#  - AZ_ORG:  The URL of your Azure DevOps organization.
#  - AZURE_DEVOPS_EXT_PAT: A Personal Access Token (PAT) with permissions:
#  - Agent Pools: Read & Manage
#  - Service Connections: Read, query, & manage
#
# For Agent Pool Creation:
#  - AZ_POOL: The desired name for the new agent pool.
#
# For Service Connection Creation:
#  - AZ_RM_SERVICE_CONN: The desired name for the ARM service connection.
#  - AZ_GH_SERVICE_CONN: The desired name for the GHCR service connection.
#  - AZ_DEVOPS_SP_ID: The Client ID (or Application ID) of the SP.
#  - AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY: The Client Secret of the SP.
#  - AZ_DEVOPS_SUBSCR_ID: The ID of the target Azure subscription.
#  - AZ_DEVOPS_SUBSCR_NAME: The name of the target Azure subscription.
#  - AZ_DEVOPS_TENANT_ID: The Azure AD Tenant ID where the SP resides.
#
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status.
set -e
set -o pipefail
set -u

# Source the environment variables
source ./_build-az-devops-vars.sh

# Helper function to format log messages with timestamp
console_log() {
    DATE_FORMAT=`date +"%Y-%m-%d %H:%M:%S"`
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
REQUIRED_VARS=(
  "AZ_ORG"
  "AZ_PROJECT"
  "AZURE_DEVOPS_EXT_PAT"
  "AZ_POOL"
  "AZ_RM_SERVICE_CONN"
  "AZ_GH_SERVICE_CONN"
  "AZ_DEVOPS_SP_ID"
  "GH_USER"
  "GH_TOKEN"
  "AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY"
  "AZ_DEVOPS_SUBSCR_ID"
  "AZ_DEVOPS_SUBSCR_NAME"
  "AZ_DEVOPS_TENANT_ID"
)

for VAR_NAME in "${REQUIRED_VARS[@]}"; do
  check_env_var "${VAR_NAME}"
done

# Check for required tools
if ! command -v az &> /dev/null; then
    console_log "Error: 'az' (Azure CLI) is required. Please install it."
    exit 1
fi

console_log "Initial checks passed."

# Log in to Azure CLI using the Service Principal
console_log "Logging into Azure with Service Principal..."
az login --service-principal \
  -u "${AZ_DEVOPS_SP_ID}" \
  -p "${AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY}" \
  --tenant "${AZ_DEVOPS_TENANT_ID}" > /dev/null

# Log in to Azure DevOps non-interactively
console_log "Logging into Azure DevOps organization: ${AZ_ORG}"
echo "${AZURE_DEVOPS_EXT_PAT}" | az devops login --organization "${AZ_ORG}" > /dev/null

# Set the default organization. This helps ensure that all subsequent 'az devops'
# commands are correctly recognized by the CLI.
az devops configure --defaults organization="${AZ_ORG}" > /dev/null

# Create Organizational Agent Pool
console_log "Checking for existing agent pool: '${AZ_POOL}'..."

# Check if the agent pool exists. Creation is supported only via DevOps portal.
POOL_ID=$(az pipelines pool list --organization "${AZ_ORG}" --query "[?name=='${AZ_POOL}'].id" -o tsv)

if [ -n "$POOL_ID" ]; then
  console_log "Agent pool '${AZ_POOL}' exists."
else
  console_log "Agent pool '${AZ_POOL}' does not exist. Please create it on the DevOps portal."
  exit 1
fi

# Create Azure RM Service Connection
console_log "Creating Azure RM Service Connection: '${AZ_RM_SERVICE_CONN}'..."

# Check if the service connection already exists to make the script idempotent
SC_ID=$(az devops service-endpoint list --organization "${AZ_ORG}" --project "$AZ_PROJECT" --query "[?name=='${AZ_RM_SERVICE_CONN}'].id" -o tsv)
if [ ! -z "$SC_ID" ]; then
  console_log "Service connection '${AZ_RM_SERVICE_CONN}' already exists. Skipping creation."
else
  # For automation, the service principal secret must be passed via this specific environment variable.
  export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY

  az devops service-endpoint azurerm create \
    --name "${AZ_RM_SERVICE_CONN}" \
    --azure-rm-service-principal-id "${AZ_DEVOPS_SP_ID}" \
    --azure-rm-subscription-id "${AZ_DEVOPS_SUBSCR_ID}" \
    --azure-rm-subscription-name "${AZ_DEVOPS_SUBSCR_NAME}" \
    --azure-rm-tenant-id "${AZ_DEVOPS_TENANT_ID}" \
    --organization "${AZ_ORG}" \
    --project "$AZ_PROJECT" > /dev/null
  
  console_log "Service connection '${AZ_RM_SERVICE_CONN}' created successfully."
fi

# Create Github Container Registry Service Connection
console_log "Creating Github Container Registry Service Connection: '${AZ_GH_SERVICE_CONN}'..."

# Check if the service connection already exists to make the script idempotent
SC_ID=$(az devops service-endpoint list --organization "${AZ_ORG}" --project "$AZ_PROJECT" --query "[?name=='${AZ_GH_SERVICE_CONN}'].id" -o tsv)
if [ ! -z "$SC_ID" ]; then
  console_log "Service connection '${AZ_GH_SERVICE_CONN}' already exists. Skipping creation."
else
  # Create a temporary JSON file for the service endpoint configuration
  cat > ghcr-config.json <<EOF
{
  "authorization": { "scheme": "UsernamePassword", "parameters": { "username": "${GH_USER}", "password": "${GH_TOKEN}", "registry": "https://ghcr.io" } },
  "name": "${AZ_GH_SERVICE_CONN}",
  "type": "dockerregistry",
  "url": "https://ghcr.io"
}
EOF
  az devops service-endpoint create \
    --service-endpoint-configuration ghcr-config.json \
    --organization "${AZ_ORG}" \
    --project "$AZ_PROJECT" > /dev/null
  console_log "Service connection '${AZ_GH_SERVICE_CONN}' created successfully."
  rm ghcr-config.json # Clean up the temporary file
fi

console_log "Azure DevOps setup complete."