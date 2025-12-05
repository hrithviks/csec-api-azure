#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.

# Compares an installed version with a required version.
# $1: Tool name (e.g., "Terraform")
# $2: Installed version
# $3: Required version
check_version() {
  tool_name=$1
  installed_version=$2
  required_version=$3

  if [ -n "$required_version" ]; then
    echo "Checking ${tool_name} version..."
    echo "  Required: ${required_version}"
    echo "  Installed: ${installed_version}"

    if [ "$installed_version" != "$required_version" ]; then
      echo "Error: Mismatched ${tool_name} version. Halting execution." >&2
      exit 1
    fi
    echo "  Version OK."
  fi
}

# Terraform Version Check
# Extracts the installed Terraform version (e.g., "1.9.0") and compares it.
INSTALLED_TERRAFORM_VERSION=$(terraform version | head -n 1 | awk '{print $2}' | sed 's/v//')
check_version "Terraform" "$INSTALLED_TERRAFORM_VERSION" "$REQ_TERRAFORM_VERSION"

# Azure CLI Version Check
# Extracts the installed Azure CLI version and compares it.
INSTALLED_AZ_VERSION=$(az --version | head -n 1 | awk '{print $2}')
check_version "Azure CLI" "$INSTALLED_AZ_VERSION" "$REQ_AZ_VERSION"

echo "---"
echo "All version checks passed. Executing command..."
echo "---"

# Execute the command passed to the container (e.g., 'terraform plan')
exec "$@"