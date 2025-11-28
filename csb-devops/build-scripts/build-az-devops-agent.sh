#!/bin/bash
#
# -----------------------------------------------------------------------------
#
# Script      : build-az-devops-agent.sh
# Description : This script provisions an Azure Virtual Machine and configures 
#               it as a self-hosted Azure DevOps agent. It automates the 
#               following steps:
#
#  1.  Performs initial checks for required tools and environment variables.
#  2.  Provisions Azure Virtual Machine
#  3.  Generates a cloud-init script to configure the VM on its first boot.
#  4.  The cloud-init script installs Docker, Azure CLI, and other dependencies.
#  5.  The cloud-init script downloads, configures, and registers the Azure
#       DevOps agent to run as a systemd service.
#
# Pre-requisites:
#  1. Azure CLI (`az`) must be installed and you must be logged in (`az login`).
#  2. `jq` must be installed for JSON parsing.
#  3. The following environment variables must be set:
#   - AZ_ORG : Azure DevOps organization URL 
#     (e.g., "https://dev.azure.com/org-name").
#   - AZ_PAT : A Personal Access Token with "Agent Pools (Read, Manage)" scope.
#   - AZ_POOL: The name of the agent pool to register the agent in.
#
# NOTE: This script provides a complete end-to-end solution suitable for
# demonstrations or small-scale setups, a more robust and scalable 
# enterprise-grade approach is recommended using Infrastructure as Code (IaC) 
# and Configuration Management tools.
#
# 1. Provisioning Azure resources, including Virtual Machines via Terraform
# 2. Use Ansible playbooks to configure the Virtual Machine after provisioning.
#
# This combination allows you to build immutable "golden images" with Packer,
# further speeding up agent provisioning and ensuring consistency.
#
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status.
set -e
set -u
set -o pipefail

# Source the env vars
source ./_build-az-devops-vars.sh

# Configuration
AZ_AGENT_NAME="csec-az-agent-$(openssl rand -hex 3)" # Unique agent name
AGENT_VERSION="4.265.1"

# Azure Infrastructure Configuration
RESOURCE_GROUP="csec-az-devops-rg"
LOCATION="southeastasia"
VNET_NAME="csec-az-devops-vnet"
SUBNET_NAME="csec-az-devops-snet"
VM_NAME="${AZ_AGENT_NAME}-vm"
VM_IMAGE="Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest"
VM_SIZE="Standard_B1ms"
ADMIN_USER="azureuser"

# Helper function to format log messages with timestamp
console_log() {
    DATE_FORMAT=`date +"%Y-%m-%d %H:%M:%S"`
    echo "$DATE_FORMAT :: $1"
}

# Helper function to check the environment variables
check_env_var() {
    VAR_NAME=$1
    if [ -z "$VAR_NAME" ]; then
        console_log "Error: $VAR_NAME environment variable is not set."
        exit 1
    fi  
}

console_log "Performing initial checks..."
 
# Check for required environment variables
for VAR in "AZ_ORG" "AZ_PAT" "AZ_POOL"; do
  check_env_var $VAR
done

# Check for required tools
if ! command -v az &> /dev/null || ! command -v jq &> /dev/null; then
    console_log "Error: 'az' (Azure CLI) and 'jq' are required. Please install them."
    exit 1
fi

console_log "Initial checks passed."

# Check if a VM with the agent name prefix already exists
console_log "Checking for existing agent VMs in resource group '${RESOURCE_GROUP}'..."
EXISTING_VM=$(az vm list --resource-group "${RESOURCE_GROUP}" --query "[?starts_with(name, 'csec-az-agent-')].name" -o tsv)

if [ -n "$EXISTING_VM" ]; then
    console_log "An existing agent VM found: ${EXISTING_VM}."
    console_log "To re-create, please delete the existing agent via console."
    exit 1
fi

# Generate VM initialization script.
console_log "Generating cloud-init configuration..."

cat > cloud-init.yaml <<EOF
#cloud-config
package_update: true
package_upgrade: true
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - software-properties-common
  - jq
  - docker.io
runcmd:
  # Wait for public DNS resolution to become available by querying a public DNS server directly.
  # This bypasses potential VNet custom DNS issues during initial boot.
  - |
    until dig @8.8.8.8 download.agent.dev.azure.com +short | grep .; do
      echo "Waiting for public DNS resolution..."
      sleep 10
    done
  # Install Azure CLI
  - curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  # Add azureuser to the docker group to run docker commands without sudo
  - sudo usermod -aG docker ${ADMIN_USER}
  # Configure and run agent
  - cd /home/${ADMIN_USER}
  - mkdir agent && cd agent
  - wget -O vsts-agent.tar.gz https://download.agent.dev.azure.com/agent/4.265.1/vsts-agent-linux-x64-4.265.1.tar.gz
  - tar -zxvf vsts-agent.tar.gz
  - chmod -R 777 /home/${ADMIN_USER}/agent
  - sudo -u ${ADMIN_USER} ./config.sh --unattended --url "${AZ_ORG}" --auth pat --token "${AZ_PAT}" --pool "${AZ_POOL}" --agent "${AZ_AGENT_NAME}" --acceptTeeEula --work _work --replace
  - sudo ./svc.sh install ${ADMIN_USER}
  - sudo ./svc.sh start
EOF

console_log "cloud-init.yaml generated."

# Check for SSH passphrase and generate keys if needed
SSH_KEY_PATH="$HOME/.ssh/id_rsa_az_agent"
if [ ! -f "${SSH_KEY_PATH}" ]; then
  console_log "Generating new SSH key at ${SSH_KEY_PATH}..."
  ssh-keygen -t rsa -b 2048 -f "${SSH_KEY_PATH}" -N "${AZ_SSH_PSWD:-}"
  console_log "SSH key generated."
fi

# Get the full ID of the subnet from the specified VNet resource group.
console_log "Fetching details for subnet '${SUBNET_NAME}' in VNet '${VNET_NAME}'..."
SUBNET_ID=$(az network vnet subnet show \
  --resource-group "${RESOURCE_GROUP}" \
  --vnet-name "${VNET_NAME}" \
  --name "${SUBNET_NAME}" \
  --query id -o tsv)

# Provision the Azure VM
console_log "Provisioning Azure infrastructure for agent: ${VM_NAME}..."
VM_OUTPUT=$(az vm create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${VM_NAME}" \
  --image "${VM_IMAGE}" \
  --size "${VM_SIZE}" \
  --admin-username "${ADMIN_USER}" \
  --ssh-key-values "${SSH_KEY_PATH}.pub" \
  --subnet "${SUBNET_ID}" \
  --custom-data cloud-init.yaml \
  --public-ip-sku Standard \
  --query "{publicIp:publicIpAddress, fqdn:fqdns}" \
  -o json)

PUBLIC_IP=$(echo "$VM_OUTPUT" | jq -r .publicIp)

console_log "Success! Agent VM '${VM_NAME}' is being provisioned with Public IP: ${PUBLIC_IP}"
console_log "Watch for the agent '${AZ_AGENT_NAME}' to appear in the '${AZ_POOL}' pool in Azure DevOps."

# Clean up local cloud-init file
rm cloud-init.yaml

# Verify Agent Status
console_log "Waiting for VM to finish configuration..."
sleep 200 # Give cloud-init time to run

console_log "Connecting to VM via SSH to verify agent status..."
ssh -o StrictHostKeyChecking=no -i "${SSH_KEY_PATH}" "${ADMIN_USER}@${PUBLIC_IP}" '
  echo "Checking Azure DevOps Agent Service Status..."
  sudo systemctl status "vsts.agent.${AZ_ORG_NAME}.${AZ_AGENT_NAME}.service" --no-pager || echo "Agent service not found or has an error."
'

console_log "Verification complete. Check the output above for the agent service status."
